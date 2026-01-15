#version 150

uniform sampler2D InSampler;
uniform vec4 ColorModulator;

layout(std140) uniform Globals {
    vec2 ScreenSize;
    float GlintAlpha;
    float GameTime;
    float MenuBlurRadius;
};

in vec2 texCoord;
in vec4 vertexColor;

out vec4 fragColor;

const float PI = 3.141592653589793;

// Must match your plugin encoding

const float BASE_TICKS = 6000.0;
const float MAX_SIGNAL_TICKS = 400.0;

float wrapSigned(float x, float period) {
    return mod(x + period * 0.5, period) - period * 0.5;
}

vec2 rotateUV(vec2 uv, float a) {
    vec2 p = uv - 0.5;
    float s = sin(a), c = cos(a);
    p = mat2(c, -s,
             s,  c) * p;
    return p + 0.5;
}

void main() {
    // sample ONE pixel from the input and stretch it to the whole screen
    fragColor = texture(InSampler, vec2(0.0, 0.0)) * vertexColor * ColorModulator;
}