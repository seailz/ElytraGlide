#ifndef EG_EFFECTS_FRAGMENT
#define EG_EFFECTS_FRAGMENT

// =============================================================================
// ElytraGlide Fragment Effects Library
// - Small helpers (hash/noise)
// - Reusable building blocks (grading, haze, overlays)
// - Presets: WINTER (blizzard), HOT (desert heat), CAVE (dark cave haze)
// =============================================================================



// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

// Hash 2D -> 0..1 pseudo-random value
float eg_hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Smooth value-noise for a 2D point
float eg_smoothnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = eg_hash12(i);
    float b = eg_hash12(i + vec2(1.0, 0.0));
    float c = eg_hash12(i + vec2(0.0, 1.0));
    float d = eg_hash12(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// -----------------------------------------------------------------------------
// WINTER preset rendering
// -----------------------------------------------------------------------------

// Strong winter color grading (contrast, colder balance, desaturation)
vec3 eg_grade_winter_strong(vec3 c) {
    c = clamp(c, 0.0, 1.0);

    c = (c - 0.5) * 1.18 + 0.56;
    c *= vec3(0.82, 0.93, 1.28);

    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));

    float shadow = smoothstep(0.62, 0.10, l);
    c += shadow * vec3(-0.04, -0.01, 0.10);

    float highlight = smoothstep(0.60, 0.95, l);
    c = mix(c, c * vec3(0.96, 0.98, 1.02), highlight);

    c = mix(vec3(l), c, 0.68);

    return clamp(c, 0.0, 1.0);
}

// Cold haze mix toward white-blue based on distance
vec3 eg_cold_haze_strong(vec3 c, float dist01) {
    vec3 hazeColor = vec3(0.92, 0.95, 1.00);
    float haze = smoothstep(0.02, 1.0, dist01);
    haze = haze * haze;
    haze *= 0.88;
    return mix(c, hazeColor, clamp(haze, 0.0, 1.0));
}

// Snow dot shape (soft circle with vertical bias)
float eg_snow_dot(vec2 f, vec2 center, float rad) {
    vec2 d = f - center;
    d.y *= 0.35;
    float dist = length(d);
    return smoothstep(rad, rad * 0.20, dist);
}

// Procedural snow layer with cell-based flakes and motion
float eg_snow_layer(vec2 uvSquare, float t, float scale, float fallSpeed, float windStrength, float density) {
    vec2 p = uvSquare * scale;
    p.y += t * fallSpeed;

    float gust = (eg_smoothnoise(vec2(p.y * 0.12, t * 0.08)) - 0.5) * 2.0;
    p.x += gust * windStrength;

    vec2 baseCell = floor(p);
    vec2 f = fract(p);

    float best = 0.0;

    // Sample current cell and neighbors
    for (int oy = -1; oy <= 1; oy++) {
        for (int ox = -1; ox <= 1; ox++) {
            vec2 cell = baseCell + vec2(float(ox), float(oy));
            float r = eg_hash12(cell);
            float present = smoothstep(1.0 - density - 0.03, 1.0 - density + 0.03, r);

            vec2 center = vec2(eg_hash12(cell + 17.0), eg_hash12(cell + 29.0));
            float rad = mix(0.05, 0.18, eg_hash12(cell + 91.0));

            vec2 ff = f - vec2(float(ox), float(oy));
            float flake = eg_snow_dot(ff, center, rad) * present;
            best = max(best, flake);
        }
    }

    return clamp(best, 0.0, 1.0);
}

// Whiteout veil + moving noise for storm effect
float eg_whiteout(vec2 uv, float t, float dist01) {
    float veil = smoothstep(0.08, 1.0, dist01) * 0.78;
    float n = eg_smoothnoise(uv * 7.5 + vec2(t * 0.22, -t * 0.16));
    veil += (n - 0.5) * 0.16;

    vec2 d = uv - 0.5;
    float v = smoothstep(0.06, 0.70, dot(d, d));
    veil += v * 0.28;

    veil += 0.08;

    return clamp(veil, 0.0, 1.0);
}

// Compose full winter effect: grading, haze, flakes, veil
vec4 winter_effect(vec4 color, float gameTime, vec2 screenUV, float viewDist) {
    float t = gameTime * 6000;
    float dist01 = clamp(viewDist / 160.0, 0.0, 1.0);

    vec3 c = eg_grade_winter_strong(color.rgb);
    c = eg_cold_haze_strong(c, dist01);

    float s1 = eg_snow_layer(screenUV, t, 140.0, 0.65, 1.20, 0.16);
    float s2 = eg_snow_layer(screenUV, t,  80.0, 0.45, 1.40, 0.14);
    float s3 = eg_snow_layer(screenUV, t,  40.0, 0.25, 1.60, 0.12);

    float snow = (s1 * 0.55 + s2 * 0.75 + s3) * 0.85;
    float veil = eg_whiteout(screenUV, t, dist01);

    vec3 snowCol = vec3(0.92, 0.96, 1.00);
    c = mix(c, snowCol, clamp(snow, 0.0, 1.0));
    c = mix(c, vec3(0.86, 0.90, 1.00), veil);

    return vec4(clamp(c, 0.0, 1.0), color.a);
}

// -----------------------------------------------------------------------------
// HOT / DESERT preset rendering
// -----------------------------------------------------------------------------

// Desert color grading (warm, contrasty)
vec3 eg_grade_hot_desert(vec3 c) {
    c = clamp(c, 0.0, 1.0);
    c = (c - 0.5) * 1.10 + 0.54;
    c *= vec3(1.10, 1.05, 0.92);

    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    float highlight = smoothstep(0.55, 0.95, l);
    c += highlight * vec3(0.06, 0.03, -0.02);

    float shadow = smoothstep(0.50, 0.10, l);
    c += shadow * vec3(-0.01, 0.00, 0.03);

    c = mix(vec3(l), c, 0.92);

    return clamp(c, 0.0, 1.0);
}

// Heat haze wash based on view distance and subtle screen noise
vec3 eg_heat_haze_wash(vec3 c, float viewDist, vec2 uv, float t) {
    vec3 hazeColor = vec3(1.00, 0.92, 0.78);
    const float CLEAR_NEAR_BLOCKS = 1.5;
    const float FULL_FAR_BLOCKS  = 5.0;

    float noise = eg_smoothnoise(uv * 6.0 + vec2(t * 0.00012, -t * 0.00008));
    noise = (noise - 0.5) * 2.0;
    float jitter = noise * 2;
    float nearRadius = max(0.0, CLEAR_NEAR_BLOCKS + jitter);

    float haze = smoothstep(nearRadius, FULL_FAR_BLOCKS, viewDist);
    haze = haze * haze;
    haze *= 0.6;

    return mix(c, hazeColor, clamp(haze, 0.0, 1.0));
}

// Shimmer mask for heat ripples based on noise + distance
float eg_heat_shimmer_mask(vec2 uv, float t, float dist01) {
    float ts = t * 0.25;
    float far = smoothstep(0.10, 1.0, dist01);

    float n1 = eg_smoothnoise(uv * 10.0 + vec2(ts * 0.40, -ts * 0.25));
    float n2 = eg_smoothnoise(uv * 22.0 + vec2(-ts * 0.70, ts * 0.50));
    float n  = (n1 * 0.65 + n2 * 0.35);

    n = smoothstep(0.52, 0.82, n);
    n = pow(n, 1.6);

    float horizon = smoothstep(0.20, 0.85, 1.0 - uv.y);
    float strength = 0.35 + 0.45 * far + 0.20 * horizon;

    return clamp(n * strength, 0.0, 1.0);
}

// Apply shimmer color shift and veil using mask
vec3 eg_apply_heat_shimmer(vec3 c, vec2 uv, float t, float dist01) {
    float m = eg_heat_shimmer_mask(uv, t, dist01);
    vec3 veilCol = vec3(1.00, 0.93, 0.80);
    c = mix(c, veilCol, m * 0.18);
    c.r += m * 0.028;
    c.b -= m * 0.022;
    return clamp(c, 0.0, 1.0);
}

// Compose full hot desert effect
vec4 hot_desert_effect(vec4 color, float gameTime, vec2 uv01, float viewDist) {
    float t = gameTime * 14000.0;
    float dist01 = clamp(viewDist * 0.02, 0.0, 1.0);
    dist01 = max(dist01, clamp(viewDist * 2.0, 0.0, 1.0));

    vec3 c = eg_grade_hot_desert(color.rgb);
    c = eg_heat_haze_wash(c, viewDist, uv01, t);
    c = eg_apply_heat_shimmer(c, uv01, t, dist01);

    return vec4(c, color.a);
}


// -----------------------------------------------------------------------------
// CAVE preset rendering
// -----------------------------------------------------------------------------

// Cave color grading (contrast, teal shadows, warm highlights)
vec3 eg_grade_cave(vec3 c) {
    c = clamp(c, 0.0, 1.0);
    c = (c - 0.5) * 1.12 + 0.50;
    c *= vec3(1.02, 1.00, 0.96);

    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    float shadow = smoothstep(0.45, 0.08, l);

    float shadowLift = -0.03;
    vec3 tealTint = vec3(0.00, 0.03, 0.05);
    c += shadow * (vec3(shadowLift) + tealTint);

    c -= shadow * vec3(0.03);

    float highlight = smoothstep(0.55, 0.95, l);
    vec3 orangeHighlight = vec3(0.14, 0.08, -0.06);
    c += highlight * orangeHighlight;

    c = mix(vec3(l), c, 0.85);

    return clamp(c, 0.0, 1.0);
}

// Damp cave haze mix using view distance and subtle noise
vec3 eg_cave_damp_haze(vec3 c, float viewDist, vec2 uv, float t) {
    vec3 hazeColor = vec3(0.22, 0.26, 0.32);
    const float CLEAR_NEAR_BLOCKS = 3;
    const float FULL_FAR_BLOCKS  = 10;

    float noise = eg_smoothnoise(uv * 6.0 + vec2(t * 0.00012, -t * 0.00008));
    noise = (noise - 0.5) * 2.0;
    float jitter = noise * 2;
    float nearRadius = max(0.0, CLEAR_NEAR_BLOCKS + jitter);

    float haze = smoothstep(nearRadius, FULL_FAR_BLOCKS, viewDist);
    haze = haze * haze;
    haze *= 0.6;

    return mix(c, hazeColor, clamp(haze, 0.0, 1.0));
}

// Radial vignette factor (0 center -> 1 edges)
float eg_vignette(vec2 uv) {
    vec2 d = uv - 0.5;
    float r2 = dot(d, d);
    return smoothstep(0.12, 0.70, r2);
}

// Film grain value (finer, low amplitude)
float eg_film_grain(vec2 uv, float t) {
    float n = eg_smoothnoise(uv * 880.0 + vec2(t * 0.15, -t * 0.10));
    return (n - 0.5) * 0.45;
}

// Compute luminance of a color
float eg_luminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// Estimate torch strength from brightness and distance
float eg_torch_strength(vec3 litColor, float viewDist) {
    float lum = eg_luminance(litColor);
    float bright = smoothstep(0.55, 0.90, lum);
    float near = 1.0 - smoothstep(6.0, 24.0, viewDist);
    return clamp(bright * near, 0.0, 1.0);
}

// Apply local torch bloom/haze to color
vec3 eg_apply_torch_haze(vec3 c, float torch, vec2 uv) {
    if (torch <= 0.001) return c;

    vec3 glowCol = vec3(1.00, 0.72, 0.38);
    vec2 d = uv - 0.5;
    float r = dot(d, d);

    float bloom = smoothstep(0.25, 0.02, r);
    bloom *= torch;

    c = mix(c, glowCol, bloom * 0.35);
    c += glowCol * bloom * 0.08;

    return clamp(c, 0.0, 1.0);
}

// Apply warm volumetric scattering from torches across screen
vec3 eg_apply_torch_air_haze(vec3 c, float torch, vec2 uv01, float dist01) {
    vec3 hazeCol = vec3(1.00, 0.78, 0.45);
    float wide = 1.0 - smoothstep(0.0, 0.85, length(uv01 - 0.5));
    float height = smoothstep(0.15, 0.85, 1.0 - uv01.y);
    float far = smoothstep(0.25, 1.0, dist01);

    float n = eg_smoothnoise(uv01 * 7.0);
    float veil = wide * (0.35 + 0.65 * height) * (0.35 + 0.65 * far) * (0.90 + 0.10 * n);

    float amt = torch * veil * 0.35;
    c = mix(c, hazeCol, amt);
    c += hazeCol * (amt * 0.10);

    return clamp(c, 0.0, 1.0);
}

// Compose full cave effect with haze, torch glows, vignette and grain
vec4 cave_effect(vec4 color, float gameTime, vec2 screenUV, float viewDist) {
    float t = gameTime * 3000.0;
    float dist01 = clamp(viewDist / 160.0, 0.0, 1.0);

    vec3 c = eg_grade_cave(color.rgb);
    c = eg_cave_damp_haze(c, viewDist, screenUV, t);

    float torch = eg_torch_strength(color.rgb, viewDist);
    c = eg_apply_torch_haze(c, torch, screenUV);
    c = eg_apply_torch_air_haze(c, torch, screenUV, dist01);

    float v = eg_vignette(screenUV);
    c *= (1.0 - v * 0.28);

    float g = eg_film_grain(screenUV, t);
    c += g * 0.015;

    return vec4(clamp(c, 0.0, 1.0), color.a);
}

// -----------------------------------------------------------------------------
// Presets (public API)
// -----------------------------------------------------------------------------
// Currently set to WINTER.
vec4 eg_apply_fragment_effects(vec4 color, float gameTime, vec2 screenUV, float viewDist) {
    return winter_effect(color, gameTime, screenUV, viewDist);
}

#endif
