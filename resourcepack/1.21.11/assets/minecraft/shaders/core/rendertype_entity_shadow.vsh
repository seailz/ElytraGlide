#version 150

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <elytraglide:eg_effects_vertex.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;


#moj_import <minecraft:globals.glsl>


out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;

void main() {
    vec4 clip = ProjMat * ModelViewMat * vec4(Position, 1.0);

    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);

   clip = eg_apply_vertex_effects(clip, GameTime);
gl_Position = clip;

    vertexColor = Color;
    texCoord0 = UV0;
}