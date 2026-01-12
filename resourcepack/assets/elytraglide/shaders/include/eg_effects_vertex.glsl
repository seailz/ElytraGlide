#ifndef EG_EFFECTS_VERTEX
#define EG_EFFECTS_VERTEX
/*
    EG Effects Vertex Library (core-shader include)
*/

/* ============================================================================
   1) BUS CONFIG
   ============================================================================ */

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

vec4 eg_example_roll(vec4 clip, float gameTime01) {
    float a = eg_roll_angle(gameTime01);
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
    // Convert ticks -> seconds-ish (20 tps)
    float t = dayTicks * (1.0 / 20.0);

    // Mix sines so it’s not perfectly periodic
    float jx = sin(t * 37.0) + sin(t * 71.0 + 1.3);
    float jy = sin(t * 41.0 + 2.1) + sin(t * 89.0 + 0.7);

    // Roughly normalize to [-1, 1]
    return 0.5 * vec2(jx, jy);
}

vec4 eg_example_shake(vec4 clip, float gameTime01) {
    float shakeOn = eg_is_max_signal(gameTime01);

    // Use raw dayTicks for motion (even if quantized signal is stable for a few ticks)
    float dayTicks = gameTime01 * 24000.0;
    vec2 jitter = eg_shake_jitter(dayTicks);

    // Apply in NDC space: multiply by clip.w so offset is constant in screen space
    clip.xy += jitter * (EG_SHAKE_MAX_NDC * shakeOn) * clip.w;
    return clip;
}

/* ============================================================================
   5) USER HOOK: ADD YOUR OWN EFFECT HERE
   ----------------------------------------------------------------------------

   Tip:
     - Prefer using eg_bus_value(gameTime01) for continuous controls [-1..+1]
     - Prefer eg_is_max_signal(gameTime01) for discrete triggers
   ============================================================================ */

vec4 eg_user_effect(vec4 clip, float gameTime01) {
    // Default: no-op. Replace with your own logic.
    return clip;
}

/* ============================================================================
   6) MAIN ENTRYPOINT
   ----------------------------------------------------------------------------
   Choose ONE:
     - eg_example_roll(clip, gameTime01)
     - eg_example_shake(clip, gameTime01)
     - eg_user_effect(clip, gameTime01)
   ============================================================================ */

vec4 eg_apply_vertex_effects(vec4 clip, float gameTime01) {
    // --- pick your effect implementation ---
    // return eg_example_roll(clip, gameTime01);
    return eg_example_shake(clip, gameTime01);
    // return eg_user_effect(clip, gameTime01);
}

#endif
