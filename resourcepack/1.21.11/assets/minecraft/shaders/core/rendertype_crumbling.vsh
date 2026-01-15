#version 330
#moj_import <elytraglide:eg_effects_vertex.glsl>
#moj_import <minecraft:globals.glsl>



#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in vec2 UV2;
in vec3 Normal;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out vec2 texCoord2;

void main() {
    vec4 eg_clip = ProjMat * ModelViewMat * vec4(Position, 1.0);
    eg_clip = eg_apply_vertex_effects(eg_clip, GameTime);
    gl_Position = eg_clip;

    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
    vertexColor = Color;
    texCoord0 = UV0;
    texCoord2 = UV2;
}