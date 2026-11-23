// Lfo.h - one LFO: a phase that goes round once a cycle, and Didgeridoo's seven shapes of it
// (DidgeridooEngine.cpp, turnLfos). Steps and Wander draw their levels from the LFO's own
// generator (dsp/noise.h, from Didgeridoo), so that an LFO restarted with the same seed repeats
// exactly.
//
// The LFO's state does not depend on its shape: the phase moves by the rate, and a new random
// level is drawn at every new cycle whatever the shape. The shape only says what value the
// state stands for, so a voice can copy the engine's free-running LFO and read it with its own
// shape.

#pragma once

#include "dsp/noise.h"

#include "Params.h"

#include <cmath>
#include <cstdint>

namespace fanfrnoch {

// From Didgeridoo's dsp/math.h (MIT): the fractional part of a phase, and a parabolic sine of
// a phase in cycles (~1 % THD, fine for an LFO).
inline float wrapPhase(float p)
{
    p -= (float)std::floor(p);
    return p;
}

inline float fastSin01(float phase)
{
    float x = 1.0f - 2.0f * wrapPhase(phase);   // 1..-1 so that phase 0.25 -> +1
    return 4.0f * x * (1.0f - std::fabs(x));    // parabola, peak +-1 at x = +-0.5
}

struct Lfo
{
    float phase = 0.0f;              // 0..1, in cycles
    float from = 0.0f, to = 0.0f;    // Steps holds `to`; Wander moves from `from` to `to`
    mpc::dsp::Xorshift32 rng;

    // Back to the start of a cycle with a fresh generator. The first level is drawn at once, so
    // that Steps already holds a random level in its first cycle and Wander moves there from
    // the middle.
    void restart(uint32_t seed)
    {
        phase = 0.0f;
        rng.reseed(seed);
        from = 0.0f;
        to = rng.nextBipolar();
    }

    // One control tick on: `increment` is the rate in cycles per tick.
    void advance(float increment)
    {
        float p = phase + increment;
        if (p >= 1.0f)                       // a new cycle: Steps and Wander take a new level
        {
            p = wrapPhase(p);
            from = to;
            to = rng.nextBipolar();
        }
        phase = p;
    }

    // Where the LFO stands now, -1..+1, for one of the shapes (LfoShape).
    float value(int shape) const
    {
        switch (shape)
        {
            case kLfoSine:     return fastSin01(phase);
            case kLfoTriangle: return phase < 0.25f ? 4.0f * phase : (phase < 0.75f ? 2.0f - 4.0f * phase : 4.0f * phase - 4.0f);
            case kLfoRampUp:   return 2.0f * phase - 1.0f;
            case kLfoRampDown: return 1.0f - 2.0f * phase;
            case kLfoSquare:   return phase < 0.5f ? 1.0f : -1.0f;
            case kLfoSteps:    return to;
            default:           return from + (to - from) * phase * phase * (3.0f - 2.0f * phase);
        }
    }
};

} // namespace fanfrnoch
