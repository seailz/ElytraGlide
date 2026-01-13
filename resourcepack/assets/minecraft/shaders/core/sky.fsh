#version 150

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <elytraglide:eg_effects_fragment.glsl>

in float sphericalVertexDistance;
in float cylindricalVertexDistance;

out vec4 fragColor;

layout(std140) uniform Globals {
    vec2 ScreenSize;
    float GlintAlpha;
    float GameTime;
    float MenuBlurRadius;
};

void main() {
    vec2 screenUV = gl_FragCoord.xy / ScreenSize;

    // Apply your blizzard look to the *sky color* too.
    // This is crucial so snow/whiteout shows even when looking at open sky.
    vec4 color = eg_apply_fragment_effects(ColorModulator, GameTime, screenUV, sphericalVertexDistance);

    // Then let vanilla sky fog happen on top.
    fragColor = apply_fog(
        color,
        sphericalVertexDistance,
        cylindricalVertexDistance,
        0.0, FogSkyEnd, FogSkyEnd, FogSkyEnd,
        FogColor
    );
}
