#version 150

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <elytraglide:eg_effects_vertex.glsl>


layout(std140) uniform Globals {
    vec2 ScreenSize;      // aka OutSize
    float GlintAlpha;
    float GameTime;       // 0..1 over 20 minutes (fractional day)
    float MenuBlurRadius;
};

in vec3 Position;
in vec4 Color;
in vec2 UV0;

out vec4 vertexColor;
out vec2 texCoord0;

void main() {
    vec4 clip = ProjMat * ModelViewMat * vec4(Position, 1.0);

   clip = eg_apply_vertex_effects(clip, GameTime);
gl_Position = clip;

    vertexColor = Color;
    texCoord0 = UV0;
}