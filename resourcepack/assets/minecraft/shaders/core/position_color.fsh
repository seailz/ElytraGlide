#version 150

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <elytraglide:eg_effects_fragment.glsl>

in vec4 vertexColor;

out vec4 fragColor;

layout(std140) uniform Globals {
    vec2 ScreenSize;
    float GlintAlpha;
    float GameTime;
    float MenuBlurRadius;
};

void main() {
    vec4 color = vertexColor;

vec2 screenUV = gl_FragCoord.xy / ScreenSize;

    // Sky pass: force "far" distance so haze/whiteout/shimmer is strong.
    float viewDist = 200.0;

    // Treat this like a sky tint (similar to sky.fsh)
    vec4 outColor = eg_apply_fragment_effects(color * ColorModulator, GameTime, screenUV, viewDist);

    fragColor = outColor;
    if (color.a == 0.0) {
        discard;
    }
}
