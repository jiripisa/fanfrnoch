// FanfrnochReference.cpp - the listening prototype's voice and renderer, copied from
// .planning/research/spike/fanfrnoch_spike.cpp (lines 30-371), as the reference the engine is
// tested against. Throwaway code: do not "fix" or tidy it.
//
// Amended where the engine must differ, each marked "amended":
//   * the rate is a variable (the spike's is a constant 48 kHz). The DC blocker's coefficient,
//     the Scrape's and the Creak's noise and the Creak's impulses are scaled so that they sound
//     at every rate as at 48 kHz; at 48 kHz every scale is 1 and the numbers are the spike's;
//   * an event names the parameter set of its stroke (the spike's drum has one), so that the
//     pads of one group, one drum, can each have their own;
//   * the key's release is an event (`noteOff`) that sets the stroke's `hold` to the time the
//     stroke has run, as a note-off does in real time, instead of a hold known at the stroke;
//   * a stroke on a drum whose voice is silent (never struck, or retired after its ring-out)
//     starts a fresh voice, seeded with the render's next seed (1, 2, 3, ...) and keeping the
//     drum's stroke count, as the engine does (the spike struck its one voice again, and seeded
//     each drum with a seed of its own). The spike's polyphonic drum (render 13b, the restarts
//     the design turned down) is left out;
//   * events are sorted stably, so that two at one time keep their order;
//   * 2 to a power is std::exp2(x), which an optimised build of the spike calls for its
//     std::pow(2.0, x) (the two differ in a last bit now and then), so that debug and release
//     builds of this copy render the same;
//   * the voices' sum can go through the engine's half-band decimator (HalfBand.h), as the
//     engine's does below 88.2 kHz.
// Checked once outside the suite (phase 02's VERIFICATION.md): at 48 kHz this copy writes the
// spike's renders byte for byte where no voice retires between strokes and no key is let go.
//
// No fused multiply-add: the rendering must be the same in debug and release builds.
#pragma clang fp contract(off)

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <random>
#include <string>
#include <vector>

#include "../../Sources/FanfrnochDSP/HalfBand.h"

static thread_local double SR = 48000.0;   // amended: a variable (one per thread: tests render in parallel)
static constexpr double kPi = 3.14159265358979323846;

struct Params
{
    // Stroke
    float attack = 42.0f;     // ms, -20 dB to -3 dB
    float length = 230.0f;    // ms the hand rubs
    float release = 0.30f;    // s, T60 once the hand stops
    float damp = 0.0f;        // 0..1, release up to 3x faster
    bool keyupStop = false;   // note-off stops the rubbing early
    float alternate = 2.0f;   // dB quieter on every second stroke of the drum
    float alttune = 10.0f;    // cents on every second stroke
    float vary = 0.2f;        // 0..1 stroke-to-stroke spread
    float velsens = 0.7f;
    // Pitch
    float scoop = 0.0f;       // semitones below at the onset
    float scooptime = 80.0f;  // ms to arrive
    float drift = -0.8f;      // semitones over the plateau
    float drop = 0.0f;        // semitones in the release
    float wobble = 20.0f;     // cents rms
    float jump = 0.0f;        // 0..1 share of strokes ending on the Skin mode
    float jumpratio = 1.40f;
    float veltune = 0.0f;     // cents at full velocity
    // Source
    float stick = 0.88f;      // 0.5..0.95
    float stickvel = 0.03f;   // how much Stick falls as the level falls
    float split = 0.0f;       // 0..1 alternate periods unequal
    float creak = 0.0f;       // 0..1
    float creakrate = 14.0f;  // Hz
    float creakring = 40.0f;  // ms
    // Body
    float pot = 500.0f, potq = 4.0f, potlevel = -200.0f;    // Hz, Q, dB (-200 = off)
    float skin = 306.0f, skinq = 10.0f, skinlevel = -200.0f;
    float track = 0.0f;       // 0..1 body follows the pitch
    // Noise
    float rub = -10.0f;       // dB against the tone (-200 = off)
    float scrape = 0.1f;      // 0..1
    float shimmer = 0.7f;     // dB rms
};

static float dbToGain(float db) { return db <= -150.0f ? 0.0f : std::pow(10.0f, db / 20.0f); }

// Trapezoidal state-variable band-pass, normalised to unity gain at its centre.
struct Bandpass
{
    double g = 0, k = 1, a1 = 1, a2 = 0, a3 = 0, ic1 = 0, ic2 = 0;
    void set(double hz, double q)
    {
        hz = std::min(hz, SR * 0.45);
        g = std::tan(kPi * hz / SR);
        k = 1.0 / q;
        a1 = 1.0 / (1.0 + g * (g + k));
        a2 = g * a1;
        a3 = g * a2;
    }
    double process(double x)
    {
        double v3 = x - ic2;
        double v1 = a1 * ic1 + a2 * v3;
        double v2 = ic2 + a2 * ic1 + a3 * v3;
        ic1 = 2 * v1 - ic1;
        ic2 = 2 * v2 - ic2;
        return k * v1;  // band-pass, peak gain 1
    }
};

// One-pole low-passed gaussian-ish noise with unit rms.
struct SlowNoise
{
    double a = 0, y = 0, norm = 1;
    void set(double hz)
    {
        a = 1.0 - std::exp(-2.0 * kPi * hz / SR);
        norm = std::sqrt((2.0 - a) / a);
    }
    double process(double white) { y += a * (white - y); return y * norm; }
};

struct Event
{
    double time;       // s
    int drum;
    double hz;
    float vel;         // 0..1
    const Params* p;   // amended: the stroke's parameter set
    bool noteOff;      // amended: the key is let go here
};

struct Voice
{
    const Params* p = nullptr;
    std::mt19937 rng;
    std::uniform_real_distribution<double> uni{-1.0, 1.0};
    double white() { return uni(rng); }
    double gauss() { return (uni(rng) + uni(rng) + uni(rng)) * 1.0; }  // rms ~1

    // stroke state
    bool active = false;
    double t = 0, tRelease = -1;   // time in stroke, time since the hand stopped
    double len = 0.23, hold = -1;
    double f0 = 123.47, vel = 1;
    double levelGain = 1, centsOffset = 0;
    bool jumping = false;
    int strokeCount = 0;
    // running state
    double phase = 0, e1 = 0, e2 = 0;
    bool longPeriod = false;
    double jumpSemis = 0;
    double scrapeEnv = 0;
    double creakTimer = 0;
    SlowNoise wob, shim;
    Bandpass pot, skin, noiseBand, scrapeBand, creakRes;
    double dcX = 0, dcY = 0;

    void init(const Params* params, uint32_t seed)
    {
        p = params;
        rng.seed(seed);
        wob.set(30.0);
        shim.set(20.0);
        scrapeBand.set(2500.0, 0.7);
    }

    void strike(const Event& e)
    {
        p = e.p;   // amended: the stroke's parameter set
        const Params& P = *p;
        active = true;
        t = 0;
        tRelease = -1;
        f0 = e.hz;
        vel = e.vel;
        hold = -1;   // amended: given by a note-off event
        bool second = (strokeCount % 2) == 1;
        ++strokeCount;
        double v = P.vary;
        len = P.length / 1000.0 * (1.0 + 0.2 * (v / 0.2) * 0.5 * white());
        len = std::max(0.0, len);
        double levelDb = 1.5 * (v / 0.2) * 0.5 * white();
        centsOffset = 25.0 * (v / 0.2) * 0.5 * white();
        if (second) { levelDb -= P.alternate; centsOffset += P.alttune; }
        centsOffset += P.veltune * vel;
        double velGain = 1.0 - P.velsens * (1.0 - vel);
        levelGain = dbToGain(float(levelDb)) * velGain;
        jumping = (uni(rng) * 0.5 + 0.5) < P.jump;
        jumpSemis = 0;
        scrapeEnv = P.scrape;
        // body follows the pitch by Track
        double ratio = std::pow(f0 / 123.47, P.track);
        pot.set(P.pot * ratio, P.potq);
        skin.set(P.skin * ratio, P.skinq);
        noiseBand.set(std::max(2.0 * f0, 150.0), 0.7);
        double ringQ = kPi * P.skin * ratio * (P.creakring / 1000.0) / 6.91;
        creakRes.set(P.skin * ratio, std::max(1.0, ringQ));
    }

    // amended: the key is let go; the hand stops here with Key Up = Stop
    void release() { if (hold < 0) hold = t; }

    double process()
    {
        if (!active) return 0;
        const Params& P = *p;
        const double dt = 1.0 / SR;
        const double noiseScale = std::sqrt(SR / 48000.0), kickScale = SR / 48000.0;   // amended: 1 at 48 kHz

        // hand: is it still rubbing?
        double stopAt = len;
        if (P.keyupStop && hold >= 0) stopAt = std::min(stopAt, hold);
        bool rubbing = t < stopAt;
        if (!rubbing && tRelease < 0) tRelease = 0;

        // envelope: two cascaded one-poles (the head's inertia), exponential ring-out
        double tau = (P.attack / 1000.0) / 1.95;
        double a = 1.0 - std::exp(-dt / tau);
        if (rubbing)
        {
            e1 += a * (1.0 - e1);
            e2 += a * (e1 - e2);
        }
        else
        {
            double t60 = P.release / (1.0 + 2.0 * P.damp);
            double r = std::exp(-6.91 * dt / t60);
            e1 *= r;
            e2 *= r;
        }
        double env = e2;

        // pitch
        double semis = 0;
        if (P.scoop > 0) semis -= P.scoop * std::exp(-t / (P.scooptime / 1000.0 / 3.0));
        semis += P.drift * std::min(1.0, t / std::max(1e-3, len));
        if (tRelease >= 0) semis -= P.drop * (1.0 - std::exp(-tRelease / 0.015));
        if (jumping && t > 0.7 * len)
        {
            double target = 12.0 * std::log2(P.jumpratio);
            jumpSemis += (target - jumpSemis) * (1.0 - std::exp(-dt / 0.004));
        }
        semis += jumpSemis;
        semis += (centsOffset + P.wobble * wob.process(gauss())) / 100.0;
        double hz = f0 * std::exp2(semis / 12.0);   // amended: exp2, as an optimised build calls

        // clock with Split: alternate periods longer and shorter
        double splitAmt = 0.35 * P.split;
        double inc = hz / SR * (longPeriod ? (1.0 - splitAmt) : (1.0 + splitAmt));
        phase += inc;
        if (phase >= 1.0) { phase -= 1.0; longPeriod = !longPeriod; }

        // shape: warped cosine; stick fraction darkens as the level falls
        double s = P.stick - P.stickvel * (1.0 - env * (0.5 + 0.5 * vel)) * 3.0;
        s = std::clamp(s, 0.5, 0.97);
        double tone = (phase < s) ? -std::cos(kPi * phase / s)
                                  : -std::cos(kPi * (1.0 + (phase - s) / (1.0 - s)));
        bool slipping = phase >= s;
        // Split also changes the amplitude of alternate periods a little
        if (P.split > 0) tone *= longPeriod ? (1.0 + 0.3 * P.split) : (1.0 - 0.3 * P.split);

        // creak: separate slips at Creak Rate, each ringing the Skin mode
        double creakOut = 0;
        if (P.creak > 0)
        {
            creakTimer -= dt;
            double kick = 0;
            if (creakTimer <= 0 && rubbing)
            {
                creakTimer = (1.0 / P.creakrate) * (1.0 + 0.3 * white());
                kick = 1.0;
            }
            creakOut = creakRes.process(kick * 40.0 * kickScale + 0.05 * white() * noiseScale) * 3.0;   // amended: scales
        }
        double source = (1.0 - P.creak) * tone + P.creak * creakOut;

        // rub noise: gated by the stroke, partly synchronous with the slips
        double noise = 0;
        float rubGain = dbToGain(P.rub);
        if (rubGain > 0)
        {
            double band = std::min(1.0, 1.4 * std::max(2.0 * f0, 150.0) / (SR / 2));
            double comp = 0.7 / (0.577 * std::sqrt(band));
            double n = noiseBand.process(white()) * comp;
            noise = n * rubGain * (0.4 + 0.6 * (slipping ? 1.0 : 0.25)) * (0.5 + 0.5 * vel);
        }
        // scrape at the onset (about 20 ms)
        double scrapeOut = 0;
        if (scrapeEnv > 1e-4)
        {
            scrapeOut = scrapeBand.process(white() * noiseScale) * scrapeEnv * 2.0;   // amended: scale
            scrapeEnv *= std::exp(-dt / 0.007);
        }

        double excitation = (source + noise) * env;
        double out = excitation
                   + pot.process(excitation) * dbToGain(P.potlevel) * 2.0
                   + skin.process(excitation) * dbToGain(P.skinlevel) * 2.0
                   + scrapeOut;
        out *= levelGain * dbToGain(float(P.shimmer * shim.process(gauss())));

        // DC blocker
        double y = out - dcX + (1.0 - 0.0005 * (48000.0 / SR)) * dcY;   // amended: 0.9995 at 48 kHz
        dcX = out;
        dcY = y;

        t += dt;
        if (tRelease >= 0)
        {
            tRelease += dt;
            if (tRelease > P.release * 3.0 + 0.1 && env < 1e-5) active = false;
        }
        return y;
    }
};

struct Drum
{
    std::vector<Voice> voices;
};

static std::vector<double> render(std::vector<Drum> drums, std::vector<Event> events, size_t n)
{
    uint32_t nextSeed = 1;   // amended: the engine's seeds
    std::stable_sort(events.begin(), events.end(), [](auto& a, auto& b) { return a.time < b.time; });   // amended: stable
    std::vector<double> out(n, 0.0);
    size_t next = 0;
    for (auto& d : drums) d.voices.reserve(64);
    for (size_t i = 0; i < n; ++i)
    {
        double now = double(i) / SR;
        while (next < events.size() && events[next].time <= now)
        {
            const Event& e = events[next++];
            Drum& d = drums[size_t(e.drum)];
            if (e.noteOff)   // amended: the key's release
            {
                if (!d.voices.empty()) d.voices[0].release();
                continue;
            }
            if (d.voices.empty() || !d.voices[0].active)   // amended: a fresh voice on a silent drum
            {
                const int count = d.voices.empty() ? 0 : d.voices[0].strokeCount;
                d.voices.assign(1, Voice());
                d.voices[0].init(e.p, nextSeed++);
                d.voices[0].strokeCount = count;
            }
            d.voices[0].strike(e);
        }
        double s = 0;
        for (auto& d : drums)
            for (auto& v : d.voices) s += v.process();
        out[i] = s;
    }
    return out;
}

#include "FanfrnochReference.h"

static_assert(sizeof(FanfrnochRefParams) == 33 * 4, "the C parameters are the prototype's");

extern "C" void fanfrnoch_ref_default_params(FanfrnochRefParams* out)
{
    const Params d;
    *out = FanfrnochRefParams{
        d.attack, d.length, d.release, d.damp, d.keyupStop ? 1 : 0,
        d.alternate, d.alttune, d.vary, d.velsens,
        d.scoop, d.scooptime, d.drift, d.drop, d.wobble, d.jump, d.jumpratio, d.veltune,
        d.stick, d.stickvel, d.split, d.creak, d.creakrate, d.creakring,
        d.pot, d.potq, d.potlevel, d.skin, d.skinq, d.skinlevel, d.track,
        d.rub, d.scrape, d.shimmer };
}

static Params toParams(const FanfrnochRefParams& c)
{
    Params p;
    p.attack = c.attack; p.length = c.length; p.release = c.release; p.damp = c.damp; p.keyupStop = c.keyupStop != 0;
    p.alternate = c.alternate; p.alttune = c.alttune; p.vary = c.vary; p.velsens = c.velsens;
    p.scoop = c.scoop; p.scooptime = c.scooptime; p.drift = c.drift; p.drop = c.drop; p.wobble = c.wobble;
    p.jump = c.jump; p.jumpratio = c.jumpratio; p.veltune = c.veltune;
    p.stick = c.stick; p.stickvel = c.stickvel; p.split = c.split; p.creak = c.creak; p.creakrate = c.creakrate;
    p.creakring = c.creakring;
    p.pot = c.pot; p.potq = c.potq; p.potlevel = c.potlevel; p.skin = c.skin; p.skinq = c.skinq;
    p.skinlevel = c.skinlevel; p.track = c.track;
    p.rub = c.rub; p.scrape = c.scrape; p.shimmer = c.shimmer;
    return p;
}

extern "C" void fanfrnoch_ref_render(const FanfrnochRefEvent* events, int numEvents,
                                     const FanfrnochRefParams* paramSets, int numParamSets,
                                     int numDrums, double voiceRate, int decimate, float* out, int frames)
{
    SR = voiceRate;
    std::vector<Params> sets;
    for (int i = 0; i < numParamSets; ++i) sets.push_back(toParams(paramSets[i]));
    std::vector<Drum> drums((size_t)numDrums);
    std::vector<Event> score;
    for (int i = 0; i < numEvents; ++i)
    {
        const FanfrnochRefEvent& e = events[i];
        score.push_back(Event{ e.time, e.drum, e.hz, e.velocity, &sets[(size_t)e.params], e.noteOff != 0 });
    }
    const size_t n = (size_t)frames * (decimate ? 2 : 1);
    const std::vector<double> x = render(drums, score, n);
    if (!decimate)
    {
        for (int i = 0; i < frames; ++i) out[i] = (float)x[(size_t)i];
        return;
    }
    fanfrnoch::HalfBand decimator;
    decimator.design();
    for (int i = 0; i < frames; ++i) out[i] = decimator.process((float)x[2 * (size_t)i], (float)x[2 * (size_t)i + 1]);
}
