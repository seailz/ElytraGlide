#version 330

#moj_import <minecraft:light.glsl>
#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <elytraglide:eg_effects_vertex.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
#ifdef PER_FACE_LIGHTING
out vec4 vertexPerFaceColorBack;
out vec4 vertexPerFaceColorFront;
#else
out vec4 vertexColor;
#endif
out vec4 lightMapColor;
out vec4 overlayColor;
out vec2 texCoord0;

bool isGuiLikeRender() {
    // Perspective projection typically has ProjMat[3].w == 0
    // Ortho (GUI) typically has ProjMat[3].w == 1
    return abs(ProjMat[3].w - 1.0) < 0.0001;
}

bool isFirstPersonHand(vec3 viewPos) {
    // view space: hand/items are very close to camera
    return (viewPos.z > -1.5) && (viewPos.z < 1.5);
}

void main() {
    // View-space position (this is the coordinate space fog funcs generally expect)
    vec4 viewPos4 = ModelViewMat * vec4(Position, 1.0);
    vec3 viewPos  = viewPos4.xyz;

    // Clip-space
    vec4 clip = ProjMat * viewPos4;

    // Distances should match the same space as vanilla expects for entities
    sphericalVertexDistance   = fog_spherical_distance(viewPos);
    cylindricalVertexDistance = fog_cylindrical_distance(viewPos);

    // Apply effects only on world-perspective passes
    if (!isGuiLikeRender()) {
        // Optional: exclude first-person hand/item (uncomment if you want)
        // if (!isFirstPersonHand(viewPos)) {
        clip = eg_apply_vertex_effects(clip, GameTime);
        // }
    }

    gl_Position = clip;

    #ifdef PER_FACE_LIGHTING
    vec2 light = minecraft_compute_light(Light0_Direction, Light1_Direction, Normal);
    vertexPerFaceColorBack = minecraft_mix_light_separate(-light, Color);
    vertexPerFaceColorFront = minecraft_mix_light_separate(light, Color);
    #elif defined(NO_CARDINAL_LIGHTING)
    vertexColor = Color;
    #else
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    #endif

    #ifndef EMISSIVE
    lightMapColor = texelFetch(Sampler2, UV2 / 16, 0);
    #endif
    overlayColor = texelFetch(Sampler1, UV1, 0);

    texCoord0 = UV0;
    #ifdef APPLY_TEXTURE_MATRIX
    texCoord0 = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
    #endif
}
