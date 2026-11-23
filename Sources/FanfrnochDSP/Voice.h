// Voice.h - one drum's head under the hand: the listening prototype's voice (.planning/research/
// spike/fanfrnoch_spike.cpp, Bandpass, SlowNoise and Voice), ported line for line.
//
// What differs from the prototype:
//   * the rate is the engine's internal rate, not a fixed 48 kHz. The parts of the voice that
//     depend on the rate sound at every rate as they do at 48 kHz, the rate the author approved
//     by ear: the DC blocker's corner, the level of the Scrape's and the Creak's noise and the
//     height of the Creak's impulses (each scale is 1 at 48 kHz, so there the numbers are the
//     prototype's);
//   * the knobs come from a KnobView (plain values), which the engine computes for the voice
//     (Engine::viewFor): the knob set, moved by the voice's LFOs, the stroke's velocity and,
//     for a keyboard voice, the wheels. Each control tick turns the view into the prototype's
//     Params (`DrumKnobs`: percent knobs as fractions, a level at the bottom of its knob as the
//     prototype's -200 dB) and works out what the prototype computes from them every sample:
//     the envelope's coefficients, the levels, the body's filters;
//   * what the prototype takes at the stroke (Length, Vary's draws, Alternate and Alt Tune, the
//     velocity's gain and pitch, Jump's draw, Scrape) is taken from the stroke's view; every
//     other knob is read again at each control tick, so that a keyboard voice follows the knobs
//     while it sounds and the LFOs move it;
//   * Tune and the pitch bend are added to the pitch in semitones, after the prototype's own
//     pitch (0 for both leaves the prototype's numbers);
//   * 2 to a power is std::exp2, not std::pow(2.0, x): an optimised build turns the one into the
//     other, and the two differ in a last bit now and then, so a debug build would render other
//     samples than a release build (the spike, built with -O2, called exp2 too);
//   * the note-off of the stroke's note gives the prototype's `hold`: the hand stops there when
//     Key Up is Stop;
//   * a body resonance whose level is off, a Drop of 0 and a Shimmer of 0 skip work whose result
//     the prototype multiplies by 0 (the random draws stay where they were); a pitch above the
//     internal rate, which the prototype never reaches, keeps the phase within its period;
//   * the output gain is Volume times VEL>Volume's gain, and Pan splits it into two channels; a
//     stolen voice fades out (choke);
//   * each voice owns two LFOs, which step at its control tick.
//
// A voice belongs to a drum (FanfrnochEngine.cpp): a stroke on a drum that sounds continues its
// voice, as the prototype's mono drum does: strike() re-arms the stroke and keeps the phase, the
// envelope, the filters, the noise and the random generator running.
//
// Each expression keeps the prototype's order of operations and its random draws, so that fixed
// knobs give the prototype's numbers.

#pragma once

#include "Lfo.h"
#include "Params.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <random>

namespace fanfrnoch {

constexpr double kPi = 3.14159265358979323846;

// The rate the prototype ran at and the author listened at.
constexpr double kApprovedRate = 48000.0;

// The plain values a voice reads, in table order; VEL>Volume's linear gain, since Volume's VEL
// amount scales the level instead of moving the knob; and the pitch bend in semitones.
struct KnobView
{
    float v[kNumParams];
    float velocityGain = 1.0f;
    float bend = 0.0f;
};

struct StereoSample { float l, r; };

// Where a voice's stroke comes from: a key in keyboard mode, or a pad in pad mode. `note` is the
// MIDI note that struck it, whose note-off stops the hand; a pad's voice sounds at its pad's note
// instead. `group` is the pad's group at the stroke (0 = Off).
enum OriginKind { kOriginKey, kOriginPad };

struct Origin
{
    int kind = kOriginKey;
    int note = 0;
    int pad = -1;
    int group = 0;
};

// The drums a voice can belong to: the keyboard with Drum One, a note with Drum Many, a group of
// pads, or a pad whose group is Off.
enum DrumId
{
    kDrumKeyboard = 0,
    kDrumFirstNote = 1,                                       // + note
    kDrumFirstGroup = kDrumFirstNote + 128,                   // + group - 1
    kDrumFirstPad = kDrumFirstGroup + FANFRNOCH_NUM_GROUPS,   // + pad
    kNumDrums = kDrumFirstPad + FANFRNOCH_NUM_PADS
};

// The prototype's dB to gain: -150 dB and below is silence (its "off" levels are -200 dB).
inline float dbToGain(float db) { return db <= -150.0f ? 0.0f : std::pow(10.0f, db / 20.0f); }

constexpr float kOffDb = -200.0f;

// Trapezoidal state-variable band-pass, normalised to unity gain at its centre.
struct Bandpass
{
    double g = 0, k = 1, a1 = 1, a2 = 0, a3 = 0, ic1 = 0, ic2 = 0;
    void set(double hz, double q, double rate)
    {
        hz = std::min(hz, rate * 0.45);
        g = std::tan(kPi * hz / rate);
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
    void set(double hz, double rate)
    {
        a = 1.0 - std::exp(-2.0 * kPi * hz / rate);
        norm = std::sqrt((2.0 - a) / a);
    }
    double process(double white) { y += a * (white - y); return y * norm; }
};

// The prototype's Params: the knobs in its units, as this control tick sees them.
struct DrumKnobs
{
    float attack = 42.0f, length = 230.0f, release = 0.30f, damp = 0.0f;
    bool keyupStop = false;
    float alternate = 2.0f, alttune = 10.0f, vary = 0.2f, velsens = 0.7f;
    float scoop = 0.0f, scooptime = 80.0f, drift = -0.8f, drop = 0.0f, wobble = 20.0f, jump = 0.0f,
          jumpratio = 1.40f, veltune = 0.0f;
    float stick = 0.88f, stickvel = 0.03f, split = 0.0f, creak = 0.0f, creakrate = 14.0f, creakring = 40.0f;
    float pot = 500.0f, potq = 4.0f, potlevel = kOffDb, skin = 306.0f, skinq = 10.0f, skinlevel = kOffDb,
          track = 0.0f;
    float rub = -10.0f, scrape = 0.1f, shimmer = 0.7f;
};

struct Voice
{
    bool active = false, choking = false;
    Origin origin;
    int drum = kDrumKeyboard;
    int note = 0;                   // the pitch, before the set's Octave and Tune
    double vel = 1;
    KnobView view{};
    // A pad's knob set as it stood at the stroke, normalised and as plain values: what its view
    // is computed from. A key's voice reads the keyboard set instead.
    float setAtHit[kNumParams] = {};
    float plainAtHit[kNumParams] = {};
    Lfo lfo[kNumLfos];

    double rate = kApprovedRate, dt = 1.0 / kApprovedRate;
    DrumKnobs P;

    std::mt19937 rng;
    std::uniform_real_distribution<double> uni{-1.0, 1.0};
    double white() { return uni(rng); }
    double gauss() { return (uni(rng) + uni(rng) + uni(rng)) * 1.0; }  // rms ~1

    // stroke state
    double t = 0, tRelease = -1;   // time in stroke, time since the hand stopped
    double len = 0.23, hold = -1;
    double f0 = 123.47;
    double levelGain = 1, centsOffset = 0;
    bool jumping = false;
    // running state
    double phase = 0, e1 = 0, e2 = 0;
    bool longPeriod = false;
    double jumpSemis = 0;
    double scrapeEnv = 0;
    double creakTimer = 0;
    SlowNoise wob, shim;
    Bandpass pot, skin, noiseBand, scrapeBand, creakRes;
    double dcX = 0, dcY = 0;

    // What the prototype works out from its Params every sample, worked out at each control tick.
    double envA = 0, envR = 1, jumpTarget = 0, jumpGlide = 0, rubComp = 0, pitchOffset = 0;
    float rubGain = 0, potGain = 0, skinGain = 0;
    float outGain = 1, panL = 1, panR = 1;
    // The rate's scales (1 at 48 kHz) and the DC blocker's coefficient (0.9995 at 48 kHz).
    double noiseScale = 1, kickScale = 1, dcCoeff = 0.9995;

    float chokeGain = 1, chokeMul = 1;
    int ctl = 0;

    float knob(int i) const { return view.v[i]; }

    // True when the next sample starts a control tick: the moment to refresh the view.
    bool controlDue() const { return ctl <= 0; }

    // True for a key's voice: it plays the keyboard set as it is now, whatever the mode.
    bool followsKeyboard() const { return origin.kind == kOriginKey; }

    // A fresh voice for a drum that is not sounding: the prototype's Voice::init with `seed`.
    void begin(int drumId, uint32_t seed, double internalRate)
    {
        *this = Voice();
        drum = drumId;
        rate = internalRate;
        dt = 1.0 / rate;
        rng.seed(seed);
        wob.set(30.0, rate);
        shim.set(20.0, rate);
        scrapeBand.set(2500.0, 0.7, rate);
        noiseScale = std::sqrt(rate / kApprovedRate);
        kickScale = rate / kApprovedRate;
        dcCoeff = 1.0 - 0.0005 * (kApprovedRate / rate);
        jumpGlide = 1.0 - std::exp(-dt / 0.004);
    }

    // A stroke, the prototype's strike(): the engine has set the origin, the pitch, the velocity,
    // the LFOs and the view the stroke sees. `second` is true on every second stroke of the drum.
    void strike(bool second)
    {
        readKnobs();
        active = true;
        t = 0;
        tRelease = -1;
        hold = -1;
        f0 = 440.0 * std::exp2(((double)note + 12.0 * (double)knob(kOctave) - 69.0) / 12.0);
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
        updateFilters();
        ctl = 0;
    }

    // The note-off of the stroke's note: where the hand stops with Key Up = Stop.
    void release()
    {
        if (hold < 0) hold = t;
    }

    // Fades the voice out: it falls 40 dB in `ms`.
    void choke(float ms)
    {
        if (choking) return;
        choking = true;
        const float tc = std::max(ms, 1.0f) * 0.001f / 4.6f;
        chokeMul = (float)std::exp(-1.0 / (tc * rate));
    }

    // How loud the voice is now: what voice stealing compares.
    float loudness() const { return (float)(e2 * levelGain) * chokeGain * outGain; }

    // The knobs as this tick sees them, in the prototype's units.
    void readKnobs()
    {
        const auto level = [this](int i) { return knob(i) <= param(i).min ? kOffDb : knob(i); };
        P.attack = knob(kAttack);
        P.length = knob(kLength);
        P.release = knob(kRelease);
        P.damp = knob(kDamp) / 100.0f;
        P.keyupStop = std::lround(knob(kKeyUp)) == kKeyUpStop;
        P.alternate = knob(kAlternate);
        P.alttune = knob(kAltTune);
        P.vary = knob(kVary) / 100.0f;
        P.velsens = knob(kVelSens) / 100.0f;
        P.scoop = knob(kScoop);
        P.scooptime = knob(kScoopTime);
        P.drift = knob(kDrift);
        P.drop = knob(kDrop);
        P.wobble = knob(kWobble);
        P.jump = knob(kJump) / 100.0f;
        P.jumpratio = knob(kJumpRatio);
        P.veltune = knob(kVelPitch);
        P.stick = knob(kStick);
        P.stickvel = knob(kStickVel);
        P.split = knob(kSplit) / 100.0f;
        P.creak = knob(kCreak) / 100.0f;
        P.creakrate = knob(kCreakRate);
        P.creakring = knob(kCreakRing);
        P.pot = knob(kPot);
        P.potq = knob(kPotQ);
        P.potlevel = level(kPotLevel);
        P.skin = knob(kSkin);
        P.skinq = knob(kSkinQ);
        P.skinlevel = level(kSkinLevel);
        P.track = knob(kTrack) / 100.0f;
        P.rub = level(kRub);
        P.scrape = knob(kScrape) / 100.0f;
        P.shimmer = knob(kShimmer);

        double tau = (P.attack / 1000.0) / 1.95;
        envA = 1.0 - std::exp(-dt / tau);
        double t60 = P.release / (1.0 + 2.0 * P.damp);
        envR = std::exp(-6.91 * dt / t60);
        jumpTarget = 12.0 * std::log2(P.jumpratio);
        rubGain = dbToGain(P.rub);
        potGain = dbToGain(P.potlevel);
        skinGain = dbToGain(P.skinlevel);
        pitchOffset = (double)knob(kTune) / 100.0 + (double)view.bend;
        outGain = dbToGain(knob(kVolume)) * view.velocityGain;
        const float pan = knob(kPan) / 100.0f;
        panL = std::min(1.0f, 1.0f - pan);
        panR = std::min(1.0f, 1.0f + pan);
    }

    // The body, which follows the pitch by Track, and the rub's band (the prototype sets these at
    // the stroke).
    void updateFilters()
    {
        double ratio = std::pow(f0 / 123.47, P.track);
        pot.set(P.pot * ratio, P.potq, rate);
        skin.set(P.skin * ratio, P.skinq, rate);
        noiseBand.set(std::max(2.0 * f0, 150.0), 0.7, rate);
        double ringQ = kPi * P.skin * ratio * (P.creakring / 1000.0) / 6.91;
        creakRes.set(P.skin * ratio, std::max(1.0, ringQ), rate);
        double band = std::min(1.0, 1.4 * std::max(2.0 * f0, 150.0) / (rate / 2));
        rubComp = 0.7 / (0.577 * std::sqrt(band));
    }

    // The LFOs one control tick on, each at its rate as the view has it now.
    void turnLfos()
    {
        for (int k = 0; k < kNumLfos; ++k)
            lfo[k].advance(knob(kLfo1Rate + 2 * k) * 16.0f / (float)rate);
    }

    StereoSample process()
    {
        if (ctl-- <= 0) { readKnobs(); updateFilters(); ctl = 15; }

        // hand: is it still rubbing?
        double stopAt = len;
        if (P.keyupStop && hold >= 0) stopAt = std::min(stopAt, hold);
        bool rubbing = t < stopAt;
        if (!rubbing && tRelease < 0) tRelease = 0;

        // envelope: two cascaded one-poles (the head's inertia), exponential ring-out
        if (rubbing)
        {
            e1 += envA * (1.0 - e1);
            e2 += envA * (e1 - e2);
        }
        else
        {
            e1 *= envR;
            e2 *= envR;
        }
        double env = e2;

        // pitch
        double semis = 0;
        if (P.scoop > 0) semis -= P.scoop * std::exp(-t / (P.scooptime / 1000.0 / 3.0));
        semis += P.drift * std::min(1.0, t / std::max(1e-3, len));
        if (tRelease >= 0 && P.drop != 0) semis -= P.drop * (1.0 - std::exp(-tRelease / 0.015));
        if (jumping && t > 0.7 * len)
            jumpSemis += (jumpTarget - jumpSemis) * jumpGlide;
        semis += jumpSemis;
        semis += (centsOffset + P.wobble * wob.process(gauss())) / 100.0;
        semis += pitchOffset;
        double hz = f0 * std::exp2(semis / 12.0);

        // clock with Split: alternate periods longer and shorter
        double splitAmt = 0.35 * P.split;
        double inc = hz / rate * (longPeriod ? (1.0 - splitAmt) : (1.0 + splitAmt));
        phase += inc;
        if (phase >= 1.0)
        {
            phase -= 1.0;
            longPeriod = !longPeriod;
            if (phase >= 1.0) phase -= std::floor(phase);   // a pitch above the rate (not the prototype's)
        }

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
            creakOut = creakRes.process(kick * 40.0 * kickScale + 0.05 * white() * noiseScale) * 3.0;
        }
        double source = (1.0 - P.creak) * tone + P.creak * creakOut;

        // rub noise: gated by the stroke, partly synchronous with the slips
        double noise = 0;
        if (rubGain > 0)
        {
            double n = noiseBand.process(white()) * rubComp;
            noise = n * rubGain * (0.4 + 0.6 * (slipping ? 1.0 : 0.25)) * (0.5 + 0.5 * vel);
        }
        // scrape at the onset (about 20 ms)
        double scrapeOut = 0;
        if (scrapeEnv > 1e-4)
        {
            scrapeOut = scrapeBand.process(white() * noiseScale) * scrapeEnv * 2.0;
            scrapeEnv *= std::exp(-dt / 0.007);
        }

        double excitation = (source + noise) * env;
        double out = excitation
                   + (potGain > 0 ? pot.process(excitation) * potGain * 2.0 : 0.0)
                   + (skinGain > 0 ? skin.process(excitation) * skinGain * 2.0 : 0.0)
                   + scrapeOut;
        const double wave = shim.process(gauss());
        out *= levelGain * (P.shimmer != 0 ? dbToGain(float(P.shimmer * wave)) : 1.0f);

        // DC blocker
        double y = out - dcX + dcCoeff * dcY;
        dcX = out;
        dcY = y;

        t += dt;
        if (tRelease >= 0)
        {
            tRelease += dt;
            if (tRelease > P.release * 3.0 + 0.1 && env < 1e-5) active = false;
        }
        if (choking) { chokeGain *= chokeMul; if (chokeGain < 1e-5f) active = false; }

        const float o = (float)y * outGain * chokeGain;
        return { o * panL, o * panR };
    }
};

} // namespace fanfrnoch
