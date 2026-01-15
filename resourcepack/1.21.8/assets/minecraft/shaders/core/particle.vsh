#version 150

#moj_import <minecraft:fog.glsl>
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
in vec2 UV0;
in vec4 Color;
in ivec2 UV2;

uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec2 texCoord0;
out vec4 vertexColor;

void main() {
   vec4 clip = ProjMat * ModelViewMat * vec4(Position, 1.0);

    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);

   clip = eg_apply_vertex_effects(clip, GameTime);
gl_Position = clip;

    texCoord0 = UV0;
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
}