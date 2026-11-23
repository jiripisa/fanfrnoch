// FanfrnochReference.cpp - the listening prototype's voice and renderer, copied unchanged from
// .planning/research/spike/fanfrnoch_spike.cpp (lines 14-230), as the reference the engine is
// tested against. Throwaway code: do not "fix" or tidy it.
//
// No fused multiply-add: the rendering must be the same in debug and release builds.
#pragma clang fp contract(off)

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <random>
#include <string>
#include <vector>

static constexpr double SR = 96000.0;
static constexpr double kPi = 3.14159265358979323846;

struct Params
{
    float ring = 4.0f;          // s, reed's own 60 dB time
    float edge = 18.0f;         // swing at a full stroke, in slot half-widths
    float offset = 0.2f;        // rest position against the frame plane, half-widths
    float bodyDb = -24.0f;      // reed motion heard directly, re the strongest harmonic (approx.)
    float buzz = 0.4f;          // bursts heard directly
    float clang = 0.1f;         // second bending mode in the first ~50 ms
    float velsens = 0.7f;
    int stroke = 2;             // 0 out, 1 in, 2 alternate
    float damp = 10.0f;         // ms, finger stopping the reed
    float vary = 0.2f;
    float vowel = 800.0f;       // Hz, where the moving resonance starts
    float sweep = 14.0f;        // semitones travelled during the hit
    float sweeptime = 160.0f;   // ms
    int curve = 0;              // 0 glide, 1 line, 2 there-and-back, 3 step
    float reso = 15.0f;         // Q of the moving resonance
    float throatDb = -10.0f;    // throat resonance level re the moving one
    float throattune = 430.0f;  // Hz
    float open = 0.3f;          // throat openness
    float close = 0.0f;         // tongue shutting the moving resonance
    float breath = 0.3f;        // -1 (in) .. +1 (out); 1 = half the reed's speed at a full stroke
    float puff = 0.3f;          // breath pushed at the stroke
    float pufftime = 120.0f;    // ms
    float air = 0.1f;           // breath noise
    bool levelOnlyVelocity = false;
};

// Trapezoidal state-variable band-pass (as Didgeridoo's TractResonance). Returns the band-pass
// state, whose peak gain is Q: a sharper mouth resonance rings louder, as a struck one does.
struct Reso
{
    float k = 0.1f, a1 = 1, a2 = 0, a3 = 0, ic1 = 0, ic2 = 0;
    void set(float hz, float q)
    {
        hz = std::min(hz, (float)(0.45 * SR));
        const float g = (float)std::tan(kPi * hz / SR);
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

static float dbToGain(float db) { return std::pow(10.0f, db / 20.0f); }

// Level of one harmonic the vowel resonance brings out, in the output's units, for a full
// stroke: calibrates Body against the strongest harmonic (set from --analyze).
static constexpr float kHarmonicRef = 0.35f;

// Added 2026-11-16, after the author's listening heard hiss in long tails: the slot's gate is open
// while the reed rests, so Air and the breath bias went on at a constant level until the voice
// retired. Air now fades with the reed's own decay (1 at the hit), the breath with its level:
static constexpr float kAirFadeBelow = 0.1f;        // Air fades with the reed once it is 20 dB down
static constexpr float kBreathFadeBelow = 0.001f;   // the breath fades over the 40 dB above the retire floor (1e-5): ~1 % at most when the voice retires

struct Voice
{
    bool active = false, choking = false;
    int note = 0;
    Params p;
    double phase = 0, inc = 0, t = 0;
    float swing = 1, tau = 1, dir = 1, offset = 0, vowelStart = 800, sweepTime = 0.16f;
    float vel = 1, outGain = 1, chokeGain = 1, chokeMul = 1, puffAmt = 0;
    int ctl = 0;
    float vowelHz = 800;
    Reso vowelR, throatR, highR;
    std::minstd_rand noise{1};

    void start(int n, float velocity, const Params& params, float direction, std::mt19937& rng)
    {
        *this = Voice();
        active = true; note = n; p = params; vel = velocity; dir = direction;
        const double f0 = 440.0 * std::pow(2.0, (n - 69) / 12.0);
        inc = 2 * kPi * f0 / SR;
        std::uniform_real_distribution<float> u(-1.0f, 1.0f);
        const float vy = p.vary;
        const float v = p.levelOnlyVelocity ? 1.0f : 1.0f - p.velsens * (1.0f - velocity);
        swing = v * (1.0f + 0.15f * vy * u(rng));
        outGain = p.levelOnlyVelocity ? velocity : 1.0f;
        tau = p.ring / 6.91f;
        offset = p.offset + 0.3f * vy * u(rng);
        vowelStart = p.vowel * std::pow(2.0f, 3.0f * vy * u(rng) / 12.0f);
        sweepTime = p.sweeptime * 0.001f * (1.0f + 0.2f * vy * u(rng));
        puffAmt = p.puff * (p.levelOnlyVelocity ? 1.0f : (0.3f + 0.7f * velocity));
        noise.seed((unsigned)(rng() | 1));
        ctl = 0;
    }

    void choke()
    {
        if (choking) return;
        choking = true;
        const float tc = std::max(p.damp, 1.0f) * 0.001f / 4.6f;   // -40 dB in Damp
        chokeMul = (float)std::exp(-1.0 / (tc * SR));
    }

    float shape(float x) const
    {
        x = std::clamp(x, 0.0f, 1.0f);
        switch (p.curve)
        {
            case 1: return x;
            case 2: return (float)std::sin(kPi * x);
            case 3: return x < 0.5f ? 0.0f : 1.0f;
            default: return 1.0f - (1.0f - x) * (1.0f - x) * (1.0f - x);
        }
    }

    void updateFilters()
    {
        const float tt = (float)t;
        vowelHz = std::clamp(vowelStart * std::pow(2.0f, p.sweep * shape(tt / sweepTime) / 12.0f), 150.0f, 9000.0f);
        vowelR.set(vowelHz, p.reso);
        const float q = 6.0f - 3.5f * p.open;
        throatR.set(p.throattune + 250.0f * p.open, q);
        highR.set(2800.0f, 4.0f);
    }

    float process()
    {
        if (ctl-- <= 0) { updateFilters(); ctl = 15; }
        const float a = swing * (float)std::exp(-t / tau) * chokeGain;
        const float c = (float)std::cos(phase), s = (float)std::sin(phase);
        float u = dir * p.edge * a * c + offset;
        if (p.clang > 0) u += p.clang * 3.0f * a * (float)std::exp(-t / 0.02) * (float)std::sin(6.27 * phase);
        const float v = -dir * a * s;
        const float pt = p.pufftime * 0.001f;
        const float puffEnv = t < pt ? (float)(1.0 - t / pt) : 0.0f;
        const float ra = a / swing;   // added 2026-11-16 (the author's listening): Air and breath fade with the reed
        const float gN = std::min(1.0f, ra / kAirFadeBelow);
        const float gB = std::min(1.0f, a / kBreathFadeBelow);
        const float b = gB * (0.5f * p.breath + 0.5f * puffAmt * puffEnv * (p.breath < 0 ? -1.0f : 1.0f));
        const float th = std::tanh(u);
        const float gate = 1.0f - th * th;
        float src = gate * (v + b) * std::fabs(v + b);
        const float n = (float)noise() / (float)noise.max() * 2.0f - 1.0f;
        src += gN * (p.air * 0.08f * n * (gate + 0.05f) * (0.3f + std::fabs(b)));

        const float vowelGain = (1.0f - p.close);
        const float throatGain = dbToGain(p.throatDb) * (1.0f + p.open);
        float y = vowelGain * vowelR.step(src) * (15.0f / p.reso) * std::sqrt(p.reso / 15.0f)
                + throatGain * throatR.step(src) * 2.0f
                + 0.25f * highR.step(src)
                + p.buzz * src * 1.0f
                + kHarmonicRef * dbToGain(p.bodyDb) * dir * a * c;
        y *= outGain;

        t += 1.0 / SR;
        phase += inc;
        if (phase > 2 * kPi) phase -= 2 * kPi;
        if (choking) { chokeGain *= chokeMul; if (chokeGain < 1e-5f) active = false; }
        if (a < 1e-5f && t > 0.2) active = false;
        return y;
    }
};

struct Event { double time; int note; float vel; Params p; bool chokeOnly = false; };

struct Score
{
    std::vector<Event> ev;
    void hit(double t, int note, float vel, const Params& p) { ev.push_back({t, note, vel, p, false}); }
    void chokeAt(double t, int note, const Params& p) { ev.push_back({t, note, 0, p, true}); }
};

static std::vector<float> render(Score score, double seconds)
{
    std::stable_sort(score.ev.begin(), score.ev.end(), [](const Event& a, const Event& b) { return a.time < b.time; });
    const size_t N = (size_t)(seconds * SR);
    std::vector<float> out(N, 0.0f);
    std::vector<Voice> voices(32);
    std::mt19937 rng(12345);
    int lastDir[128];
    for (int& d : lastDir) d = -1;
    size_t next = 0;
    float x1 = 0, y1 = 0;
    for (size_t i = 0; i < N; ++i)
    {
        const double now = i / SR;
        while (next < score.ev.size() && score.ev[next].time <= now)
        {
            const Event& e = score.ev[next++];
            for (Voice& v : voices) if (v.active && v.note == e.note) v.choke();
            if (e.chokeOnly) continue;
            Voice* slot = nullptr;
            for (Voice& v : voices) if (!v.active) { slot = &v; break; }
            if (!slot) slot = &voices[0];
            float dir = 1;
            if (e.p.stroke == 1) dir = -1;
            else if (e.p.stroke == 2) { lastDir[e.note] = -lastDir[e.note]; dir = (float)lastDir[e.note]; }
            slot->start(e.note, e.vel, e.p, dir, rng);
        }
        float sum = 0;
        for (Voice& v : voices) if (v.active) sum += v.process();
        const float y = sum - x1 + 0.9995f * y1;   // DC blocker
        x1 = sum; y1 = y;
        out[i] = y;
    }
    return out;
}

#include "FanfrnochReference.h"

extern "C" void fanfrnoch_ref_default_params(FanfrnochRefParams* out)
{
    const Params d;
    out->ring = d.ring; out->edge = d.edge; out->offset = d.offset; out->bodyDb = d.bodyDb;
    out->buzz = d.buzz; out->clang = d.clang; out->velsens = d.velsens; out->stroke = d.stroke;
    out->damp = d.damp; out->vary = d.vary; out->vowel = d.vowel; out->sweep = d.sweep;
    out->sweeptime = d.sweeptime; out->curve = d.curve; out->reso = d.reso;
    out->throatDb = d.throatDb; out->throattune = d.throattune; out->open = d.open;
    out->close = d.close; out->breath = d.breath; out->puff = d.puff; out->pufftime = d.pufftime;
    out->air = d.air; out->levelOnlyVelocity = d.levelOnlyVelocity ? 1 : 0;
}

static Params toParams(const FanfrnochRefParams& c)
{
    Params p;
    p.ring = c.ring; p.edge = c.edge; p.offset = c.offset; p.bodyDb = c.bodyDb;
    p.buzz = c.buzz; p.clang = c.clang; p.velsens = c.velsens; p.stroke = c.stroke;
    p.damp = c.damp; p.vary = c.vary; p.vowel = c.vowel; p.sweep = c.sweep;
    p.sweeptime = c.sweeptime; p.curve = c.curve; p.reso = c.reso;
    p.throatDb = c.throatDb; p.throattune = c.throattune; p.open = c.open;
    p.close = c.close; p.breath = c.breath; p.puff = c.puff; p.pufftime = c.pufftime;
    p.air = c.air; p.levelOnlyVelocity = c.levelOnlyVelocity != 0;
    return p;
}

extern "C" void fanfrnoch_ref_render(const FanfrnochRefEvent* events, int numEvents,
                                  const FanfrnochRefParams* paramSets, int numParamSets,
                                  float* out, int frames)
{
    std::vector<Params> sets;
    for (int i = 0; i < numParamSets; ++i) sets.push_back(toParams(paramSets[i]));
    Score score;
    for (int i = 0; i < numEvents; ++i)
    {
        const FanfrnochRefEvent& e = events[i];
        Event ev{e.time, e.note, e.velocity, sets[(size_t)e.params], e.chokeOnly != 0};
        score.ev.push_back(ev);
    }
    const std::vector<float> x = render(score, frames / SR);
    const size_t n = std::min(x.size(), (size_t)frames);
    std::copy(x.begin(), x.begin() + (std::ptrdiff_t)n, out);
    std::fill(out + n, out + frames, 0.0f);
}
