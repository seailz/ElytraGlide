#version 150

#moj_import <minecraft:light.glsl>
#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
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
out vec4 vertexColor;
out vec4 lightMapColor;
out vec4 overlayColor;
out vec2 texCoord0;

layout(std140) uniform Globals {
    vec2 ScreenSize;      // aka OutSize
    float GlintAlpha;
    float GameTime;       // 0..1 over 20 minutes (fractional day)
    float MenuBlurRadius;
};

bool isGuiLikeRender() {
    // GLSL mat4 is column-major: ProjMat[3].x == ProjMat[3][0]
    return abs(ProjMat[3].x + 1.0) < 0.0001;
}

bool isFirstPersonHand(vec3 viewPos) {
    bool veryNearViewZ = (viewPos.z > -1.5) && viewPos.z < 1.5;

    return veryNearViewZ;
}




void main() {
    vec4 clip = ProjMat * ModelViewMat * vec4(Position, 1.0);


    
sphericalVertexDistance   = fog_spherical_distance(clip.xyz);
cylindricalVertexDistance = fog_cylindrical_distance(clip.xyz);

// Items in inventories are counted as entities. By detecting what type of renderring we're using, we can exclude inventory items to prevent messing up the hotbar/creative menu
vec4 mvPos4 = ModelViewMat * vec4(Position, 1.0);
vec3 viewPos = mvPos4.xyz;
if (!isGuiLikeRender()) {
    // This if statement is commented out as enabling it can cause strange effects when getting close to entites. If you want the hand to not be affected by the shader, then uncomment this. See readme for details
    //if (!isFirstPersonHand(viewPos)) {
        clip = eg_apply_vertex_effects(clip, GameTime);
    // }
}

gl_Position = clip;

#ifdef NO_CARDINAL_LIGHTING
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