#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Tuple


VSH_IMPORT = "#moj_import <elytraglide:eg_effects_vertex.glsl>"
FSH_IMPORT = "#moj_import <elytraglide:eg_effects_fragment.glsl>"

GLOBALS_BLOCK = """layout(std140) uniform Globals {
    vec2 ScreenSize;
    float GlintAlpha;
    float GameTime;
    float MenuBlurRadius;
};
"""

VERT_SNIPPET_TEMPLATE = """{indent}vec4 eg_clip = {rhs};
{indent}eg_clip = eg_apply_vertex_effects(eg_clip, GameTime);
{indent}gl_Position = eg_clip;"""

FRAG_SNIPPET = """{indent}vec2 screenUV = gl_FragCoord.xy / ScreenSize;
{indent}color = eg_apply_fragment_effects(color, GameTime, screenUV, sphericalVertexDistance);"""


@dataclass
class EditResult:
    changed: bool
    reason: str


def detect_newline(text: str) -> str:
    # Preserve CRLF if present
    return "\r\n" if "\r\n" in text else "\n"


def find_main_span(text: str) -> Optional[Tuple[int, int]]:
    """
    Returns (start_index_of_open_brace, end_index_of_matching_close_brace+1)
    for the main() function body, or None if not found.
    """
    m = re.search(r"\bvoid\s+main\s*\(\s*\)\s*\{", text)
    if not m:
        return None
    open_brace = text.find("{", m.start())
    if open_brace == -1:
        return None

    depth = 0
    i = open_brace
    while i < len(text):
        c = text[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return open_brace, i + 1
        i += 1
    return None


def insert_import_at_top(text: str, import_line: str) -> Tuple[str, bool]:
    if import_line in text:
        return text, False

    nl = detect_newline(text)
    lines = text.splitlines(True)

    # Find where #moj_import block ends at the top
    insert_at = None
    saw_version = False

    for idx, line in enumerate(lines):
        if line.lstrip().startswith("#version"):
            saw_version = True
            continue
        if saw_version:
            if line.lstrip().startswith("#moj_import"):
                continue
            # First non-import after we’ve seen #version
            insert_at = idx
            break

    if insert_at is None:
        # Fallback: append near top
        insert_at = 1 if lines else 0

    # Insert import line with a newline
    to_insert = import_line + nl
    lines.insert(insert_at, to_insert)
    return "".join(lines), True


def ensure_globals_block(text: str) -> Tuple[str, bool]:
    # If they already have a Globals uniform block with GameTime, don’t add again
    if re.search(r"layout\s*\(\s*std140\s*\)\s*uniform\s+Globals\s*\{", text) and "GameTime" in text:
        return text, False

    nl = detect_newline(text)
    lines = text.splitlines(True)

    # Insert after #moj_import block (or after #version if no imports)
    insert_at = None
    saw_version = False
    last_import_idx = None

    for idx, line in enumerate(lines):
        if line.lstrip().startswith("#version"):
            saw_version = True
        if saw_version and line.lstrip().startswith("#moj_import"):
            last_import_idx = idx

        if saw_version and not line.lstrip().startswith("#version") and not line.lstrip().startswith("#moj_import"):
            # We reached the first non-import line after header
            insert_at = (last_import_idx + 1) if last_import_idx is not None else idx
            break

    if insert_at is None:
        insert_at = (last_import_idx + 1) if last_import_idx is not None else 0

    block = GLOBALS_BLOCK.replace("\n", nl) + nl
    lines.insert(insert_at, block)
    return "".join(lines), True


def inject_vsh_main(text: str) -> Tuple[str, bool]:
    if "eg_apply_vertex_effects" in text:
        return text, False

    span = find_main_span(text)
    if not span:
        return text, False
    body_start, body_end = span
    body = text[body_start:body_end]

    # Replace first gl_Position assignment inside main
    # Support multiline RHS up to semicolon
    m = re.search(r"(^[ \t]*)gl_Position\s*=\s*([^;]+);", body, flags=re.MULTILINE)
    if not m:
        return text, False

    indent = m.group(1)
    rhs = m.group(2).strip()

    replacement = VERT_SNIPPET_TEMPLATE.format(indent=indent, rhs=rhs)

    new_body = body[:m.start()] + replacement + body[m.end():]
    new_text = text[:body_start] + new_body + text[body_end:]
    return new_text, True


def inject_fsh_main(text: str) -> Tuple[str, bool]:
    if "eg_apply_fragment_effects" in text:
        return text, False

    span = find_main_span(text)
    if not span:
        return text, False
    body_start, body_end = span
    body = text[body_start:body_end]

    if re.search(r"\bvec2\s+screenUV\s*=\s*gl_FragCoord\.xy\s*/\s*ScreenSize\s*;", body):
        # screenUV already present; avoid duplicating
        return text, False

    # Prefer inserting after `vec4 color = ...;`
    decl = re.search(r"(^[ \t]*)vec4\s+color\s*=\s*([^;]+);", body, flags=re.MULTILINE)
    if decl:
        indent = decl.group(1)
        insert_pos = decl.end()
        snippet = detect_newline(text) + FRAG_SNIPPET.format(indent=indent)  # newline before snippet
        new_body = body[:insert_pos] + snippet + body[insert_pos:]
        return text[:body_start] + new_body + text[body_end:], True

    # Fallback: insert after first `color = ...;`
    assign = re.search(r"(^[ \t]*)color\s*=\s*([^;]+);", body, flags=re.MULTILINE)
    if assign:
        indent = assign.group(1)
        insert_pos = assign.end()
        snippet = detect_newline(text) + FRAG_SNIPPET.format(indent=indent)
        new_body = body[:insert_pos] + snippet + body[insert_pos:]
        return text[:body_start] + new_body + text[body_end:], True

    return text, False


def process_file(path: Path, dry_run: bool, backup: bool) -> EditResult:
    original = path.read_text(encoding="utf-8")
    text = original
    changed_any = False
    changes = []

    if path.suffix == ".vsh":
        text, c = insert_import_at_top(text, VSH_IMPORT); changed_any |= c;  changes += (["import"] if c else [])
        text, c = ensure_globals_block(text);            changed_any |= c;  changes += (["globals"] if c else [])
        text, c = inject_vsh_main(text);                 changed_any |= c;  changes += (["main"] if c else [])
    elif path.suffix == ".fsh":
        text, c = insert_import_at_top(text, FSH_IMPORT); changed_any |= c; changes += (["import"] if c else [])
        text, c = ensure_globals_block(text);             changed_any |= c; changes += (["globals"] if c else [])
        text, c = inject_fsh_main(text);                  changed_any |= c; changes += (["main"] if c else [])
    else:
        return EditResult(False, "skip")

    if not changed_any:
        return EditResult(False, "no changes (already injected or pattern not found)")

    if dry_run:
        return EditResult(True, "would apply: " + ", ".join(changes))

    if backup:
        bak = path.with_suffix(path.suffix + ".bak")
        if not bak.exists():
            bak.write_text(original, encoding="utf-8")

    path.write_text(text, encoding="utf-8")
    return EditResult(True, "applied: " + ", ".join(changes))


def iter_shader_files(root: Path):
    for p in root.rglob("*"):
        if p.is_file() and p.suffix in (".vsh", ".fsh"):
            yield p


def main():
    ap = argparse.ArgumentParser(description="Inject ElytraGlide shader hooks into vanilla .vsh/.fsh files.")
    ap.add_argument("dir", type=str, help="Directory containing vanilla shaders (recursively scanned).")
    ap.add_argument("--dry-run", action="store_true", help="Show what would change without writing files.")
    ap.add_argument("--no-backup", action="store_true", help="Disable .bak backups.")
    args = ap.parse_args()

    root = Path(args.dir).expanduser().resolve()
    if not root.exists() or not root.is_dir():
        raise SystemExit(f"Not a directory: {root}")

    dry_run = args.dry_run
    backup = not args.no_backup

    total = 0
    changed = 0
    skipped = 0

    for file_path in iter_shader_files(root):
        total += 1
        res = process_file(file_path, dry_run=dry_run, backup=backup)
        if res.reason.startswith("skip"):
            skipped += 1
            continue
        if res.changed:
            changed += 1
            print(f"[CHANGED] {file_path} -> {res.reason}")
        else:
            print(f"[OK]      {file_path} -> {res.reason}")

    print(f"\nDone. Scanned: {total}, changed: {changed}, skipped: {skipped}, dry-run: {dry_run}, backups: {backup}")


if __name__ == "__main__":
    main()
