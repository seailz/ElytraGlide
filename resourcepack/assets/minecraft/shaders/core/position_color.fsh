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

    float viewDist = 200.0;

    vec4 outColor = eg_apply_fragment_effects(color * ColorModulator, GameTime, screenUV, viewDist);

    fragColor = outColor;
    if (color.a == 0.0) {
        discard;
    }
}
