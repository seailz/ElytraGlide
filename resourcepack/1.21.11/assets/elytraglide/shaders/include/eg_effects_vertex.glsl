#ifndef EG_EFFECTS_VERTEX
#define EG_EFFECTS_VERTEX
/*
    EG Effects Vertex Library (core-shader include)
*/

/* ============================================================================
   LIBRARY
   ============================================================================ */

const float EG_DAY_TICKS = 24000.0;

// Packing config
const float EG_MASK_BASE   = 256.0; // mask stored in higher place value (large gap to avoid drift)
const float EG_ARG0_MAX    = 92.0; // 0..92
const float EG_ARG0_QUANT  = 1.0;  // snap to nearest tick
const float EG_ROLL_DEADZONE = 0.03; // ignore tiny arg0 to kill micro jitter
const float EG_ROLL_SOFT     = 0.10; // soften ramp-in for roll response

struct EgBus {
    int mask;      // bitset
    float arg0;    // 0..1 normalized
    float day01;   // original gameTime01
};

EgBus eg_decode_bus(float gameTime01) {
    // Reconstruct integer timeOfDay
    float payload  = clamp(floor(gameTime01 * EG_DAY_TICKS), 0.0, EG_DAY_TICKS - 1.0);
    // Snap payload to even ticks so a single +1 client drift doesn't move arg0
    payload = floor(payload * 0.5) * 2.0;

    // Decode mask + arg0 (mask in high bits so +1 tick jitter doesn't flip it)
    float maskf = floor(payload / EG_MASK_BASE);
    float arg0i = payload - maskf * EG_MASK_BASE;

    // Quantize to absorb small +/-1 tick drift from client worldAge
    arg0i = floor((arg0i / EG_ARG0_QUANT) + 0.5) * EG_ARG0_QUANT;
    arg0i = clamp(arg0i, 0.0, EG_ARG0_MAX);

    EgBus b;
    b.mask = int(maskf + 0.5);
    b.arg0 = clamp(arg0i / EG_ARG0_MAX, 0.0, 1.0);
    b.day01 = gameTime01;
    return b;
}

bool eg_has(EgBus b, int bitIndex) {
    return ((b.mask >> bitIndex) & 1) != 0;
}

float eg_arg0_signed(EgBus b) {
    // map 0..1 -> -1..+1
    return b.arg0 * 2.0 - 1.0;
}





const float EG_BASE_TICKS        = 12000.0;              // “zero” reference tick
const float EG_MAX_SIGNAL_TICKS  = 400.0;                // max magnitude from base
const float EG_QUANT_TICKS       = 10.0;                 // tick quantization step

/* ============================================================================
   2) BUS HELPERS (shared)
   ============================================================================ */

// Wrap x into [-period/2, +period/2)
float eg_wrapSigned(float x, float period) {
    return mod(x + period * 0.5, period) - period * 0.5;
}

// Quantized delta ticks relative to EG_BASE_TICKS.
// This is the core “bus decode” you can build effects on.
float eg_quant_delta_ticks(float gameTime01) {
    float dayTicks = gameTime01 * 24000.0;
    float delta = eg_wrapSigned(dayTicks - EG_BASE_TICKS, 24000.0);
    return floor(delta / EG_QUANT_TICKS) * EG_QUANT_TICKS;
}

// Normalized bus value in [-1, +1] based on quantized delta.
float eg_bus_value(float gameTime01) {
    float qDelta = eg_quant_delta_ticks(gameTime01);
    return clamp(qDelta / EG_MAX_SIGNAL_TICKS, -1.0, 1.0);
}

// True only when the bus is at its maximum (+EG_MAX_SIGNAL_TICKS) AFTER quantization.
// This corresponds to “~12400” with the default EG_BASE_TICKS=12000.
float eg_is_max_signal(float gameTime01) {
    float qDelta = eg_quant_delta_ticks(gameTime01);
    float d = abs(qDelta - EG_MAX_SIGNAL_TICKS);
    return 1.0 - step(0.5 * EG_QUANT_TICKS, d);
}









/* ============================================================================
   3) EXAMPLE EFFECT A: ROLL (disabled by default)
   ----------------------------------------------------------------------------
   - Rolls the screen based on bus value.
   - At qDelta=+400 -> +EG_MAX_ROLL_RAD
   - At qDelta=0    -> 0
   ============================================================================ */

const float EG_MAX_ROLL_RAD = radians(16.0);

float eg_roll_angle(float gameTime01) {
    return eg_bus_value(gameTime01) * EG_MAX_ROLL_RAD;
}

float eg_roll_response(float normSigned) {
    float x = clamp(normSigned, -1.0, 1.0);
    float ax = abs(x);

    float t = smoothstep(EG_ROLL_DEADZONE, EG_ROLL_SOFT, ax);

    float lin = clamp((ax - EG_ROLL_DEADZONE) / max(1e-4, 1.0 - EG_ROLL_DEADZONE), 0.0, 1.0);
    float curved = pow(lin, 1.1); // slight ease-in

    return sign(x) * mix(0.0, curved, t);
}

vec4 eg_example_roll(vec4 clip, float gameTime01) {
    float a = eg_roll_angle(gameTime01);
    float s = sin(a), c = cos(a);
    clip.xy = mat2(c, -s, s, c) * clip.xy;
    return clip;
}

// Roll driven by the bus arg0 value (used by the main entrypoint).
vec4 eg_apply_roll(vec4 clip, EgBus b) {
    float eased = eg_roll_response(eg_arg0_signed(b));
    float a = eased * EG_MAX_ROLL_RAD;
    float s = sin(a), c = cos(a);
    clip.xy = mat2(c, -s, s, c) * clip.xy;
    return clip;
}

/* ============================================================================
   4) EXAMPLE EFFECT B: SCREEN SHAKE (enabled by default)
   ----------------------------------------------------------------------------
   - Shakes only when bus is at max (+400, quantized).
   - Offsets are applied in NDC space (multiply by clip.w).
   ============================================================================ */

const float EG_SHAKE_MAX_NDC = 0.005; // ~0.005 subtle, ~0.015 violent

vec2 eg_shake_jitter(float dayTicks) {
    float t = dayTicks * (1.0 / 20.0) * 20;

    // Mix sines so it’s not perfectly periodic
    float jx = sin(t * 37.0) + sin(t * 71.0 + 1.3);
    float jy = sin(t * 41.0 + 2.1) + sin(t * 89.0 + 0.7);

    // Roughly normalize to [-1, 1]
    return 0.5 * vec2(jx, jy);
}

vec4 eg_example_shake(vec4 clip, float gameTime01) {
    float dayTicks = gameTime01 * 24000.0;
    vec2 jitter = eg_shake_jitter(dayTicks);

    clip.xy += jitter * (EG_SHAKE_MAX_NDC) * clip.w;
    return clip;
}

/* ============================================================================
   5) EXAMPLE EFFECT C: DESERT
   ----------------------------------------------------------------------------
   - Supplements the desert FSH effect by adding a wobble replicating warm air
   ============================================================================ */

float eg_hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float eg_wave(float x) {
    return sin(x) * 0.6 + sin(x * 1.7) * 0.3 + sin(x * 2.9) * 0.1;
}

vec4 eg_apply_heat_vertex_wobble(vec4 clipPos, float gameTime) {
    float t = gameTime * 2000.0;

    vec2 ndc = clipPos.xy / max(clipPos.w, 1e-5);

    float depth01 = clamp((clipPos.z / max(clipPos.w, 1e-5)) * 0.5 + 0.5, 0.0, 1.0);
    float strength = smoothstep(0.35, 1.0, depth01) * 0.0020; // keep tiny (0.0015..0.003)

    float w = eg_wave(ndc.y * 18.0 + t) + eg_wave(ndc.y * 7.0 - t * 1.3);
    float wx = w * strength;

    float wy = eg_wave(ndc.x * 10.0 + t * 0.7) * (strength * 0.35);

    clipPos.xy += vec2(wx, wy) * clipPos.w;

    return clipPos;
}

/* ============================================================================
   6) USER HOOK: ADD YOUR OWN EFFECT HERE
   ============================================================================ */

vec4 eg_user_effect(vec4 clip, float gameTime01) {
    //  Replace with your own logic.
    return clip;
}


/* ============================================================================
   6) MAIN ENTRYPOINT
   ----------------------------------------------------------------------------

    ============================================================================ */

vec4 eg_apply_vertex_effects(vec4 clip, float gameTime01) {
    const int EG_EFF_ROLL  = 0;
    const int EG_EFF_SHAKE = 1;
    const int EG_EFF_HEAT  = 2;

    EgBus b = eg_decode_bus(gameTime01);

    vec4 outClip = clip;

    if (eg_has(b, EG_EFF_ROLL))  outClip = eg_apply_roll(outClip, b);
    if (eg_has(b, EG_EFF_SHAKE)) outClip = eg_example_shake(outClip, gameTime01);
    if (eg_has(b, EG_EFF_HEAT))  outClip = eg_apply_heat_vertex_wobble(outClip, gameTime01);

    return outClip;

}

#endif
