package com.seailz.flaps.utils;

public final class FlapsCodec {
    public static final int DAY_TICKS = 24000;

    public static final int MASK_BASE = 256; // step for mask (arg0 lives in low bits)
    public static final int ARG0_MAX = 92;   // 0..92 inclusive

    // Maximum mask allowed while keeping payload within a Minecraft day
    public static final int MAX_MASK = (DAY_TICKS - 1 - ARG0_MAX) / MASK_BASE; // 93

    private FlapsCodec() {}

    /** Packs (mask, arg0i) into timeOfDay. Throws if out of range. */
    public static int packTimeOfDay(int mask, int arg0i) {
        if (mask < 0 || mask > MAX_MASK) {
            throw new IllegalArgumentException("mask out of range (0.." + MAX_MASK + "): " + mask);
        }
        if (arg0i < 0 || arg0i > ARG0_MAX) {
            throw new IllegalArgumentException("arg0i out of range (0.." + ARG0_MAX + "): " + arg0i);
        }

        int payload = mask * MASK_BASE + arg0i;
        if (payload < 0 || payload >= DAY_TICKS) { // defensive, should be impossible with MAX_MASK
            throw new IllegalStateException("payload overflow (must be < " + DAY_TICKS + "): " + payload);
        }
        return payload;
    }

    /** Converts normalized 0..1 to arg0i 0..92. */
    public static int arg0iFrom01(float arg01) {
        float clamped = clamp01(arg01);
        return Math.round(clamped * ARG0_MAX);
    }

    /** Converts signed -1..+1 to arg0i 0..92. */
    public static int arg0iFromSigned(float signed) {
        float clamped = clamp(signed, -1f, 1f);
        float arg01 = (clamped * 0.5f) + 0.5f;
        return arg0iFrom01(arg01);
    }

    public static float clamp01(float v) {
        return v < 0f ? 0f : (v > 1f ? 1f : v);
    }

    public static float clamp(float v, float lo, float hi) {
        return v < lo ? lo : (v > hi ? hi : v);
    }
}

