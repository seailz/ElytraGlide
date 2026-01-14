package com.seailz.flaps.utils.transition;

public final class FlapsEasing {
    private FlapsEasing() {}

    /** smoothstep easing (0..1) -> (0..1) */
    public static float smoothstep(float t) {
        if (t <= 0f) return 0f;
        if (t >= 1f) return 1f;
        return t * t * (3f - 2f * t);
    }
}