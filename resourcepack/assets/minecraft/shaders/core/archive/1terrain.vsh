#version 150

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;

layout(std140) uniform Globals {
    vec2 ScreenSize;      // aka OutSize
    float GlintAlpha;
    float GameTime;       // 0..1 over 20 minutes (fractional day)
    float MenuBlurRadius;
};

vec4 minecraft_sample_lightmap(sampler2D lightMap, ivec2 uv) {
    return texture(lightMap, clamp(uv / 256.0, vec2(0.5 / 16.0), vec2(15.5 / 16.0)));
}

const float PI = 3.141592653589793;

const float BASE_TICKS = 12000.0;
const float QUANT_TICKS = 10;
const float MAX_SIGNAL_TICKS = 400.0;

// feel free to tune 12–20 degrees
const float MAX_ROLL_RAD = radians(16.0);

float wrapSigned(float x, float period) {
    return mod(x + period * 0.5, period) - period * 0.5;
}


void main() {
    vec3 pos = Position + ModelOffset;

    // Compute the normal clip-space position
    vec4 clip = ProjMat * ModelViewMat * vec4(pos, 1.0);

    // Compute fog distances from the ORIGINAL (unrolled) position
    // Use .xyz to satisfy vec3 parameter types
    sphericalVertexDistance   = fog_spherical_distance(clip.xyz);
    cylindricalVertexDistance = fog_cylindrical_distance(clip.xyz);

float dayTicks = GameTime * 24000.0;
float qDayTicks = floor(dayTicks / QUANT_TICKS) * QUANT_TICKS;

float delta = wrapSigned(qDayTicks - BASE_TICKS, 24000.0);
float x = clamp(delta / MAX_SIGNAL_TICKS, -1.0, 1.0);

float a = x * MAX_ROLL_RAD;
float s = sin(a);
float c = cos(a);

// rotate in clip space
clip.xy = mat2(c, -s,
               s,  c) * clip.xy;

    gl_Position = clip;

    vertexColor = Color * minecraft_sample_lightmap(Sampler2, UV2);
    texCoord0 = UV0;
}
