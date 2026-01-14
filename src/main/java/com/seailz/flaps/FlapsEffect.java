package com.seailz.flaps;

import com.seailz.flaps.utils.FlapsCodec;

import java.util.function.BiFunction;

/**
 * Represents a single effect bit that can be toggled in the Flaps bus.
 *
 * <p>Keep in mind the bus mask is ultimately capped by
 * {@link FlapsCodec#MAX_MASK}, so high bits (≥7) or combining too many
 * bits will overflow the codec.
 *
 * <p>There are three default effects provided: ROLL, SHAKE, and HEAT_DISTORTION. If you override these in the shader, then you can use the bits 0-3 for your own effects. With the current codec, there is a limitation of 7 effects total. You may also override the codec and use your own
 * packing scheme if you wish. See {@link Flaps#setCustomTimeProvider(BiFunction)} for more details.
 */
public final class FlapsEffect {
    public static final FlapsEffect ROLL = new FlapsEffect("ROLL", 0);
    public static final FlapsEffect SHAKE = new FlapsEffect("SHAKE", 1);
    public static final FlapsEffect HEAT_DISTORTION = new FlapsEffect("HEAT_DISTORTION", 2);

    private final String id;
    private final int bit;

    private FlapsEffect(String id, int bit) {
        if (bit < 0 || bit > 6) { // bit 7 would exceed MAX_MASK in current codec
            throw new IllegalArgumentException("Bit must be between 0 and 6 (mask limited by codec)");
        }
        this.id = id;
        this.bit = bit;
    }

    /** Create a custom effect bound to a specific bit. */
    public static FlapsEffect custom(String id, int bit) {
        return new FlapsEffect(id, bit);
    }

    public int bit() {
        return bit;
    }

    /** Mask value suitable for {@link FlapsPlayerManager#enable(FlapsEffect)}. */
    public int mask() {
        return 1 << bit;
    }

    @Override
    public String toString() {
        return "FlapsEffect{" + id + ":bit=" + bit + "}";
    }
}
