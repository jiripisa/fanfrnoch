// Voice.h - one plucked reed: the listening prototype's voice (.planning/research/spike/
// fanfrnoch_spike.cpp, Reso and Voice), ported line for line.
//
// What differs from the prototype:
//   * the rate is the engine's internal rate, not a fixed 96 kHz;
//   * the knobs come from a KnobView (plain values, percent knobs divided by 100 here), which
//     the engine computes for the voice (Engine::viewFor): the knob set, moved by the voice's
//     LFOs, the hit's velocity and, for a keyboard voice, the wheels;
//   * a voice knows its origin, a key or a pad (Origin): what chokes it and which knob set it
//     plays. A key's voice plays the keyboard set as it is now; a pad's plays its pad's set as
//     it stood at the hit;
//   * Ring, Vel Sens, Stroke, Vary, Tune and Octave are taken at the hit; every other knob is
//     read again from the view at each control tick, so a voice can follow the knobs while it
//     rings. Vary's random draws are kept as factors and applied to the knob each time;
//   * the Puff is scaled by Vel Sens, as the swing is: puff * (1 - velsens * (1 - velocity));
//   * the output gain is Volume times VEL>Volume's gain, and Pan splits it into two channels;
//   * each voice owns two LFOs, which step at its control tick.
//
// Each expression keeps the prototype's order of operations, so that fixed knobs give the
// prototype's numbers.

#pragma once

#include "Lfo.h"
#include "Params.h"

#include <algorithm>
#include <cmath>
#include <random>

namespace fanfrnoch {

constexpr double kPi = 3.14159265358979323846;

// The plain values a voice reads, in table order, and VEL>Volume's linear gain: Volume's VEL
// amount scales the level instead of moving the knob.
struct KnobView
{
    float v[kNumParams];
    float velocityGain = 1.0f;
};

struct StereoSample { float l, r; };

// Where a voice comes from: a key in keyboard mode, or a pad in pad mode. `note` is the MIDI note
// that started it, whose note-off releases it; a pad's voice sounds at its pad's note instead.
// `group` is the pad's mute group at the hit (0 = Off).
enum OriginKind { kOriginKey, kOriginPad };

struct Origin
{
    int kind = kOriginKey;
    int note = 0;
    int pad = -1;
    int group = 0;
};

inline float dbToGain(float db) { return std::pow(10.0f, db / 20.0f); }

// Trapezoidal state-variable band-pass (as Didgeridoo's TractResonance). Returns the band-pass
// state, whose peak gain is Q: a sharper mouth resonance rings louder, as a struck one does.
struct Reso
{
    float k = 0.1f, a1 = 1, a2 = 0, a3 = 0, ic1 = 0, ic2 = 0;
    void set(float hz, float q, double rate)
    {
        hz = std::min(hz, (float)(0.45 * rate));
        const float g = (float)std::tan(kPi * hz / rate);
        k = 1.0f / q;
        a1 = 1.0f / (1.0f + g * (g + k)); a2 = g * a1; a3 = g * a2;
    }
    float step(float x)
    {
        const float v3 = x - ic2, v1 = a1 * ic1 + a2 * v3, v2 = ic2 + a2 * ic1 + a3 * v3;
        ic1 = 2 * v1 - ic1; ic2 = 2 * v2 - ic2;
        return v1;
    }
};

// Level of one harmonic the vowel resonance brings out, in the output's units, for a full
// stroke: calibrates Body against the strongest harmonic (the prototype's --analyze).
constexpr float kHarmonicRef = 0.35f;

// Air and the breath bias fade with the reed, as the author asked on 2026-11-16 after hearing
// hiss in long tails: the slot's gate is open while the reed rests, so both went on at a constant
// level until the voice retired. Air follows the reed's own decay (1 at the hit); the breath
// follows the reed's level, because the voice retires on a level (1e-5), however soft the hit.
constexpr float kAirFadeBelow = 0.1f;        // Air fades with the reed once it is 20 dB down
constexpr float kBreathFadeBelow = 0.001f;   // the breath fades over the 40 dB above the retire floor: ~1 % at most when the voice retires

struct Voice
{
    bool active = false, choking = false;
    Origin origin;
    int note = 0;                   // the pitch, before the set's Octave and Tune
    KnobView view{};
    // A pad's knob set as it stood at the hit, normalised and as plain values: what its view is
    // computed from. A key's voice reads the keyboard set instead.
    float setAtHit[kNumParams] = {};
    float plainAtHit[kNumParams] = {};
    double rate = 96000.0, phase = 0, inc = 0, t = 0;

    // Taken at the hit.
    float swing = 1, tau = 1, dir = 1, vel = 1, velSens = 0.7f;
    float offsetAdd = 0, vowelFactor = 1, sweepFactor = 1;   // Vary's draws

    Lfo lfo[kNumLfos];

    // Read from the view at each control tick.
    float offset = 0, vowelStart = 800, sweepTime = 0.16f, puffAmt = 0;
    float edge = 18, clang = 0, breath = 0, pufftime = 0.12f, airAmt = 0, buzz = 0, bodyGain = 0;
    float sweep = 0, reso = 15, resoGain = 1, resoNorm = 1, open = 0, throattune = 430;
    float vowelGain = 1, throatGain = 0, outGain = 1, panL = 1, panR = 1;
    int curve = kCurveGlide;

    float chokeGain = 1, chokeMul = 1;
    int ctl = 0;
    float vowelHz = 800;
    Reso vowelR, throatR, highR;
    std::minstd_rand noise{1};

    float knob(int i) const { return view.v[i]; }

    // True when the next sample starts a control tick: the moment to refresh the view.
    bool controlDue() const { return ctl <= 0; }

    // True for a key's voice: it plays the keyboard set as it is now, whatever the mode.
    bool followsKeyboard() const { return origin.kind == kOriginKey; }

    // A hit, in two steps. `take` forgets the last hit and takes the origin, the pitch and the
    // velocity; the engine then copies a pad's set, sets the LFOs and computes the view the hit
    // sees, and `start` plucks the reed with it: what is taken at the hit is taken from that view.
    void take(const Origin& from, int pitch, float velocity)
    {
        *this = Voice();
        origin = from; note = pitch; vel = velocity;
    }

    void start(float direction, std::mt19937& rng, double internalRate)
    {
        rate = internalRate;
        active = true; dir = direction;
        const double pitch = (double)note + 12.0 * (double)knob(kOctave) + (double)knob(kTune) / 100.0;
        const double f0 = 440.0 * std::pow(2.0, (pitch - 69) / 12.0);
        inc = 2 * kPi * f0 / rate;
        std::uniform_real_distribution<float> u(-1.0f, 1.0f);
        const float vy = knob(kVary) / 100.0f;
        velSens = knob(kVelSens) / 100.0f;
        const float v = 1.0f - velSens * (1.0f - vel);
        swing = v * (1.0f + 0.15f * vy * u(rng));
        tau = knob(kRing) / 6.91f;
        offsetAdd = 0.3f * vy * u(rng);
        vowelFactor = std::pow(2.0f, 3.0f * vy * u(rng) / 12.0f);
        sweepFactor = 1.0f + 0.2f * vy * u(rng);
        noise.seed((unsigned)(rng() | 1));
        ctl = 0;
    }

    // Stops the reed: it falls 40 dB in `ms`.
    void choke(float ms)
    {
        if (choking) return;
        choking = true;
        const float tc = std::max(ms, 1.0f) * 0.001f / 4.6f;
        chokeMul = (float)std::exp(-1.0 / (tc * rate));
    }

    // How loud the reed is now: what voice stealing compares.
    float loudness() const { return swing * (float)std::exp(-t / tau) * chokeGain * outGain; }

    float shape(float x) const
    {
        x = std::clamp(x, 0.0f, 1.0f);
        switch (curve)
        {
            case kCurveLine: return x;
            case kCurveThereAndBack: return (float)std::sin(kPi * x);
            case kCurveStep: return x < 0.5f ? 0.0f : 1.0f;
            default: return 1.0f - (1.0f - x) * (1.0f - x) * (1.0f - x);
        }
    }

    // The knobs as this tick sees them.
    void readKnobs()
    {
        edge = knob(kEdge);
        offset = knob(kOffset) + offsetAdd;
        bodyGain = kHarmonicRef * dbToGain(knob(kBody));
        buzz = knob(kBuzz) / 100.0f;
        clang = knob(kClang) / 100.0f;
        vowelStart = knob(kVowel) * vowelFactor;
        sweep = knob(kSweep);
        sweepTime = knob(kSweepTime) * 0.001f * sweepFactor;
        curve = std::clamp((int)std::lround(knob(kCurve)), 0, (int)kNumCurves - 1);
        reso = knob(kReso);
        resoGain = 15.0f / reso;
        resoNorm = std::sqrt(reso / 15.0f);
        open = knob(kOpen) / 100.0f;
        throattune = knob(kThroatTune);
        vowelGain = 1.0f - knob(kClose) / 100.0f;
        throatGain = dbToGain(knob(kThroat)) * (1.0f + open);
        breath = knob(kBreath) / 100.0f;
        puffAmt = knob(kPuff) / 100.0f * (1.0f - velSens * (1.0f - vel));
        pufftime = knob(kPuffTime) * 0.001f;
        airAmt = knob(kAir) / 100.0f * 0.08f;
        outGain = dbToGain(knob(kVolume)) * view.velocityGain;
        const float pan = knob(kPan) / 100.0f;
        panL = std::min(1.0f, 1.0f - pan);
        panR = std::min(1.0f, 1.0f + pan);
    }

    // The LFOs one control tick on, each at its rate as the view has it now.
    void turnLfos()
    {
        for (int k = 0; k < kNumLfos; ++k)
            lfo[k].advance(knob(kLfo1Rate + 2 * k) * 16.0f / (float)rate);
    }

    void updateFilters()
    {
        const float tt = (float)t;
        vowelHz = std::clamp(vowelStart * std::pow(2.0f, sweep * shape(tt / sweepTime) / 12.0f), 150.0f, 9000.0f);
        vowelR.set(vowelHz, reso, rate);
        const float q = 6.0f - 3.5f * open;
        throatR.set(throattune + 250.0f * open, q, rate);
        highR.set(2800.0f, 4.0f, rate);
    }

    StereoSample process()
    {
        if (ctl-- <= 0) { readKnobs(); updateFilters(); ctl = 15; }
        const float a = swing * (float)std::exp(-t / tau) * chokeGain;
        const float c = (float)std::cos(phase), s = (float)std::sin(phase);
        float u = dir * edge * a * c + offset;
        if (clang > 0) u += clang * 3.0f * a * (float)std::exp(-t / 0.02) * (float)std::sin(6.27 * phase);
        const float v = -dir * a * s;
        const float pt = pufftime;
        const float puffEnv = t < pt ? (float)(1.0 - t / pt) : 0.0f;
        const float ra = a / swing;   // the reed's own decay: 1 at the hit
        const float gN = std::min(1.0f, ra / kAirFadeBelow);
        const float gB = std::min(1.0f, a / kBreathFadeBelow);
        const float b = gB * (0.5f * breath + 0.5f * puffAmt * puffEnv * (breath < 0 ? -1.0f : 1.0f));
        const float th = std::tanh(u);
        const float gate = 1.0f - th * th;
        float src = gate * (v + b) * std::fabs(v + b);
        const float n = (float)noise() / (float)noise.max() * 2.0f - 1.0f;
        src += gN * (airAmt * n * (gate + 0.05f) * (0.3f + std::fabs(b)));

        float y = vowelGain * vowelR.step(src) * resoGain * resoNorm
                + throatGain * throatR.step(src) * 2.0f
                + 0.25f * highR.step(src)
                + buzz * src * 1.0f
                + bodyGain * dir * a * c;
        y *= outGain;

        t += 1.0 / rate;
        phase += inc;
        if (phase > 2 * kPi) phase -= 2 * kPi;
        if (choking) { chokeGain *= chokeMul; if (chokeGain < 1e-5f) active = false; }
        if (a < 1e-5f && t > 0.2) active = false;
        return { y * panL, y * panR };
    }
};

} // namespace fanfrnoch
