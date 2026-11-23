// fanfrnoch_spike.cpp - THROWAWAY listening prototype for Fanfrnoch's sound (not product code).
//
// One drum = the research report's recommended "prescribed slip clock"
// (.planning/research/reports/Friction drum acoustics and playing.md, "Recommendation for the engine"):
//   hand   a stroke: the rubbing starts, runs for Length and stops; Attack is the head's inertia,
//          Release (T60) its ring-out once the hand stops, Damp shortens it
//   clock  a phase oscillator at the note's pitch, one slip per period; Scoop, Drift, Drop,
//          Wobble and Jump move the pitch inside a stroke
//   shape  each period is a slow stick and a fast slip: a cosine whose phase is warped so its
//          rise takes Stick of the period (0.5 = sine); Split makes alternate periods unequal;
//          Creak breaks the tone into separate slips that ring the Skin mode
//   body   two fixed resonances in parallel with the direct sound: Pot and Skin
//   rub    noise gated by the stroke (partly synchronous with the slips) through the body,
//          a Scrape at the onset, Shimmer on the level
// A drum is one head: in mono mode a new stroke continues the drum's phase and level.
//
// Renders 48 kHz / 24-bit mono WAV files, peak-normalised to -1 dBFS, for the report's
// fourteen questions for the author's ear, plus the report's programs.
//
//   clang++ -std=c++17 -O2 fanfrnoch_spike.cpp -o fanfrnoch_spike && ./fanfrnoch_spike <outdir>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <random>
#include <string>
#include <vector>

static constexpr double SR = 48000.0;
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
    double hold = -1;  // s the key is held (-1: not given)
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
        const Params& P = *p;
        active = true;
        t = 0;
        tRelease = -1;
        f0 = e.hz;
        vel = e.vel;
        hold = e.hold;
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

    double process()
    {
        if (!active) return 0;
        const Params& P = *p;
        const double dt = 1.0 / SR;

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
        double hz = f0 * std::pow(2.0, semis / 12.0);

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
            creakOut = creakRes.process(kick * 40.0 + 0.05 * white()) * 3.0;
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
            scrapeOut = scrapeBand.process(white()) * scrapeEnv * 2.0;
            scrapeEnv *= std::exp(-dt / 0.007);
        }

        double excitation = (source + noise) * env;
        double out = excitation
                   + pot.process(excitation) * dbToGain(P.potlevel) * 2.0
                   + skin.process(excitation) * dbToGain(P.skinlevel) * 2.0
                   + scrapeOut;
        out *= levelGain * dbToGain(float(P.shimmer * shim.process(gauss())));

        // DC blocker
        double y = out - dcX + 0.9995 * dcY;
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
    Params params;
    bool mono = true;
    uint32_t seed = 1;
    std::vector<Voice> voices;
};

static void writeWav(const std::string& path, std::vector<double> x)
{
    double peak = 1e-9;
    for (double v : x) peak = std::max(peak, std::fabs(v));
    double g = std::pow(10.0, -1.0 / 20.0) / peak;
    FILE* f = std::fopen(path.c_str(), "wb");
    if (!f) { std::perror(path.c_str()); return; }
    uint32_t n = uint32_t(x.size()), dataBytes = n * 3, sr = uint32_t(SR);
    auto w32 = [&](uint32_t v) { std::fwrite(&v, 4, 1, f); };
    auto w16 = [&](uint16_t v) { std::fwrite(&v, 2, 1, f); };
    std::fwrite("RIFF", 1, 4, f); w32(36 + dataBytes); std::fwrite("WAVE", 1, 4, f);
    std::fwrite("fmt ", 1, 4, f); w32(16); w16(1); w16(1); w32(sr); w32(sr * 3); w16(3); w16(24);
    std::fwrite("data", 1, 4, f); w32(dataBytes);
    for (double v : x)
    {
        int32_t s = int32_t(std::lround(std::clamp(v * g, -1.0, 1.0) * 8388607.0));
        uint8_t b[3] = {uint8_t(s & 0xff), uint8_t((s >> 8) & 0xff), uint8_t((s >> 16) & 0xff)};
        std::fwrite(b, 1, 3, f);
    }
    std::fclose(f);
}

static void render(const std::string& dir, const std::string& name, std::vector<Drum> drums,
                   std::vector<Event> events)
{
    std::sort(events.begin(), events.end(), [](auto& a, auto& b) { return a.time < b.time; });
    double end = 0;
    for (auto& e : events) end = std::max(end, e.time + 1.5);
    size_t n = size_t(end * SR);
    std::vector<double> out(n, 0.0);
    size_t next = 0;
    uint32_t seedCounter = 0;
    for (auto& d : drums) d.voices.reserve(64);
    for (size_t i = 0; i < n; ++i)
    {
        double now = double(i) / SR;
        while (next < events.size() && events[next].time <= now)
        {
            const Event& e = events[next++];
            Drum& d = drums[size_t(e.drum)];
            if (d.mono)
            {
                if (d.voices.empty())
                {
                    d.voices.emplace_back();
                    d.voices.back().init(&d.params, d.seed);
                }
                d.voices[0].strike(e);
            }
            else
            {
                int count = d.voices.empty() ? 0 : d.voices.back().strokeCount;
                d.voices.emplace_back();
                d.voices.back().init(&d.params, d.seed * 7919u + (++seedCounter));
                d.voices.back().strokeCount = count;
                d.voices.back().strike(e);
            }
        }
        double s = 0;
        for (auto& d : drums)
            for (auto& v : d.voices) s += v.process();
        out[i] = s;
    }
    writeWav(dir + "/" + name + ".wav", out);
    std::printf("%s.wav  %.1f s\n", name.c_str(), end);
}

// ---------------------------------------------------------------- notes and scores

static double noteHz(double midi) { return 440.0 * std::pow(2.0, (midi - 69.0) / 12.0); }
static constexpr double B2 = 47, A3 = 57, Fs2 = 42, C2 = 36, E2 = 40, F4 = 65, G5 = 79,
                        Ds4 = 63, Cs2 = 37, Cs3 = 49, Ds2 = 39;

// Slow alternating pulls, as the loud strokes of the group take (one every 0.465 s).
static std::vector<Event> pulls(double note, int count = 10, double gap = 0.465, int drum = 0)
{
    std::vector<Event> ev;
    for (int i = 0; i < count; ++i) ev.push_back({0.3 + i * gap, drum, noteHz(note), i % 2 ? 0.8f : 0.95f});
    return ev;
}

// A carol-like accompaniment at 110 bpm in eighths, two bars, twice:  X . X x X . X x | X . X x X x X .
static std::vector<Event> groove(double note, int drum = 0, double bpm = 110)
{
    const char* bar = "X.XxX.XxX.XxXxX.";
    double eighth = 60.0 / bpm / 2.0;
    std::vector<Event> ev;
    for (int rep = 0; rep < 2; ++rep)
        for (int i = 0; i < 16; ++i)
        {
            char c = bar[i];
            if (c == '.') continue;
            ev.push_back({0.3 + (rep * 16 + i) * eighth, drum, noteHz(note), c == 'X' ? 0.95f : 0.6f});
        }
    return ev;
}

// Sixteenths at 120 bpm (125 ms), accents on the beats, two bars.
static std::vector<Event> fast(double note, int drum = 0, double bpm = 120)
{
    double sixteenth = 60.0 / bpm / 4.0;
    std::vector<Event> ev;
    for (int i = 0; i < 32; ++i)
        ev.push_back({0.3 + i * sixteenth, drum, noteHz(note), (i % 4 == 0) ? 1.0f : (i % 2 ? 0.55f : 0.75f)});
    return ev;
}

// Held notes of different lengths (for Key Up = Stop).
static std::vector<Event> held(double note)
{
    std::vector<Event> ev;
    double t = 0.3;
    double lens[] = {0.08, 0.16, 0.08, 0.3, 0.08, 0.08, 0.5, 0.16};
    for (double l : lens) { ev.push_back({t, 0, noteHz(note), 0.9f, l}); t += std::max(0.25, l + 0.15); }
    return ev;
}

static Drum drum(const Params& p, bool mono = true, uint32_t seed = 1)
{
    Drum d;
    d.params = p;
    d.mono = mono;
    d.seed = seed;
    return d;
}

// ---------------------------------------------------------------- programs (report, "Built-in programs")

static Params fanfrnoch() { return Params{}; }

static Params brummtopf()
{
    Params p;
    p.attack = 24; p.length = 80; p.release = 60.0f / 700.0f; p.pot = 540; p.potq = 4; p.potlevel = 6;
    p.rub = -10; p.wobble = 12; p.drift = 0; p.drop = 0.25f;
    return p;
}

static Params zambomba()
{
    Params p;
    p.attack = 31; p.length = 100; p.release = 60.0f / 440.0f; p.stick = 0.80f;
    p.skin = 306; p.skinlevel = -12; p.jump = 0.2f; p.jumpratio = 1.40f; p.rub = -14; p.drift = 0;
    p.drop = 0.3f;
    return p;
}

static Params putipu()
{
    Params p;
    p.attack = 170; p.length = 150; p.release = 1.5f; p.pot = 470; p.potq = 5; p.potlevel = 12;
    p.rub = -7; p.wobble = 8; p.drift = -0.5f;
    return p;
}

static Params cuica()
{
    Params p;
    p.attack = 20; p.length = 90; p.release = 0.1f; p.stick = 0.73f; p.rub = -20; p.wobble = 8;
    p.alternate = 6; p.alttune = 30; p.drop = 0.3f; p.drift = 0; p.scrape = 0.05f;
    return p;
}

static Params cuicaWhoop()
{
    Params p = cuica();
    p.scoop = 6.6f; p.scooptime = 80; p.length = 30; p.release = 0.3f; p.alternate = 0; p.alttune = 0;
    return p;
}

static Params furruco()
{
    Params p;
    p.attack = 70; p.length = 200; p.release = 60.0f / 110.0f; p.split = 0.7f; p.wobble = 45; p.rub = -5;
    p.skin = 100; p.skinq = 6; p.skinlevel = -3; p.drift = 0;
    return p;
}

static Params creak()
{
    Params p;
    p.creak = 1.0f; p.creakrate = 14; p.creakring = 40; p.skin = 300; p.length = 900; p.attack = 30;
    p.release = 0.15f; p.rub = -14; p.wobble = 0; p.drift = 0; p.scrape = 0;
    return p;
}

static Params flick()
{
    Params p;
    p.attack = 5; p.length = 0; p.release = 0.5f; p.scrape = 0.6f; p.split = 0.25f; p.stick = 0.75f;
    p.rub = -20; p.drift = 0; p.alternate = 0;
    return p;
}

static Params buhai()
{
    Params p;
    p.attack = 80; p.length = 500; p.release = 0.4f; p.rub = -6; p.wobble = 30; p.stick = 0.9f;
    p.drift = -1.0f; p.pot = 250; p.potq = 2; p.potlevel = 3;
    return p;
}

// ---------------------------------------------------------------- the renders

int main(int argc, char** argv)
{
    std::string dir = argc > 1 ? argv[1] : ".";

    // 01 Drum or synthesizer?
    render(dir, "01a_fanfrnoch_default_pulls", {drum(fanfrnoch())}, pulls(B2));
    render(dir, "01b_fanfrnoch_default_groove", {drum(fanfrnoch())}, groove(B2));
    {
        // like the group take: loud low pulls every 0.93 s, higher drums in between
        Params hi = fanfrnoch(); hi.length = 150; hi.alternate = 3;
        std::vector<Event> ev = pulls(B2, 10, 0.93, 0);
        for (int i = 0; i < 10; ++i)
        {
            ev.push_back({0.3 + 0.465 + i * 0.93, 1, noteHz(A3 - 2), 0.6f});
            ev.push_back({0.3 + 0.465 + 0.23 + i * 0.93, 2, noteHz(A3 + 3), 0.5f});
        }
        render(dir, "01c_fanfrnoch_group_like_the_recording",
               {drum(fanfrnoch()), drum(hi, true, 2), drum(hi, true, 3)}, ev);
    }

    // 02 How long is a pull?
    for (float l : {100.0f, 230.0f, 450.0f})
    {
        Params p; p.length = l;
        render(dir, "02_length_" + std::to_string(int(l)) + "ms", {drum(p)}, groove(B2));
    }
    {
        Params p; p.length = 600; p.keyupStop = true;
        render(dir, "02d_keyup_stop_note_lengths", {drum(p)}, held(B2));
    }

    // 03 How rough?
    {
        struct R { float rub, wob; const char* name; } rs[] = {
            {-20, 5, "03a_rough_smooth_rub-20_wobble5"},
            {-10, 20, "03b_rough_default_rub-10_wobble20"},
            {-6, 40, "03c_rough_rough_rub-6_wobble40"}};
        for (auto& r : rs) { Params p; p.rub = r.rub; p.wobble = r.wob; render(dir, r.name, {drum(p)}, pulls(B2)); }
    }

    // 04 How bright?
    for (float s : {0.80f, 0.88f, 0.93f})
    {
        Params p; p.stick = s;
        char n[64]; std::snprintf(n, sizeof n, "04_stick_%.2f", s);
        render(dir, n, {drum(p)}, pulls(B2));
    }
    { Params p; p.stickvel = 0; render(dir, "04d_stick_no_darkening_in_tail", {drum(p)}, pulls(B2)); }
    { Params p; p.stickvel = 0.05f; render(dir, "04e_stick_strong_darkening_in_tail", {drum(p)}, pulls(B2)); }

    // 05 Does it need a pot?
    { Params p; p.potlevel = 6; p.pot = 500; render(dir, "05_pot_500Hz_plus6dB", {drum(p)}, pulls(B2)); }

    // 06 Drift
    { Params p; p.drift = 0; render(dir, "06_drift_0", {drum(p)}, pulls(B2)); }

    // 07 Attack
    { Params p; p.attack = 15; render(dir, "07_attack_15ms", {drum(p)}, groove(B2)); }

    // 08 Release and damp
    { Params p; p.release = 0.1f; render(dir, "08a_release_600dBps", {drum(p)}, groove(B2)); }
    { Params p; p.damp = 0.5f; render(dir, "08b_damp_50", {drum(p)}, groove(B2)); }

    // 09 Two hands on a fast pattern
    {
        struct H { float alt, tune; const char* name; } hs[] = {
            {0, 0, "09a_hands_alt0_tune0"}, {2, 10, "09b_hands_alt2_tune10"}, {6, 10, "09c_hands_alt6_tune10"}};
        for (auto& h : hs)
        {
            Params p; p.alternate = h.alt; p.alttune = h.tune; p.length = 80; p.release = 0.12f;
            render(dir, h.name, {drum(p)}, fast(B2));
        }
    }

    // 10 The onset
    for (float s : {0.0f, 0.1f, 0.4f})
    {
        Params p; p.scrape = s;
        render(dir, "10_scrape_" + std::to_string(int(s * 100)), {drum(p)}, pulls(B2));
    }

    // 11 Creak and split on soft strokes
    { Params p; p.creak = 0.4f; p.skin = 300; render(dir, "11a_creak_40", {drum(p)}, pulls(B2)); }
    { Params p; p.split = 0.5f; render(dir, "11b_split_50", {drum(p)}, pulls(B2)); }

    // 12 The cuica's whoop, and a samba cuica on two pads of one group
    {
        Params soft = cuicaWhoop(); soft.scoop = 2.5f; soft.scooptime = 120;
        std::vector<Event> ev;
        for (int i = 0; i < 6; ++i) ev.push_back({0.3 + i * 0.7, 0, noteHz(F4), 0.9f});
        render(dir, "12a_cuica_whoop_soft_2.5st_120ms", {drum(soft)}, ev);
        for (auto& e : ev) e.hz = noteHz(G5);
        render(dir, "12b_cuica_whoop_6.6st_80ms", {drum(cuicaWhoop())}, ev);
        // samba: one drum, low and high strokes in sixteenths at 100 bpm
        const char* pat = "LHLLHLHLLHLLHLHH";
        double sx = 60.0 / 100.0 / 4.0;
        std::vector<Event> samba;
        for (int rep = 0; rep < 3; ++rep)
            for (int i = 0; i < 16; ++i)
                samba.push_back({0.3 + (rep * 16 + i) * sx, 0, noteHz(pat[i] == 'L' ? F4 : G5),
                                 i % 4 == 0 ? 1.0f : 0.7f});
        render(dir, "12c_cuica_samba", {drum(cuica())}, samba);
    }

    // 13 One drum (carried phase) against polyphonic restarts, fast alternation
    {
        Params p; p.length = 80; p.release = 0.2f;
        render(dir, "13a_one_drum_mono", {drum(p, true)}, fast(B2));
        render(dir, "13b_poly_restarts", {drum(p, false)}, fast(B2));
    }

    // 14 The range, with a pot, body fixed against following
    for (double note : {Ds4 - 1 /* ~300 Hz */, Cs2 - 2 /* ~60 Hz */})
        for (float tr : {0.0f, 1.0f})
        {
            Params p; p.potlevel = 6; p.track = tr;
            char n[80]; std::snprintf(n, sizeof n, "14_range_%dHz_track%d", int(noteHz(note) + 0.5), int(tr * 100));
            render(dir, n, {drum(p)}, pulls(note));
        }

    // Programs
    {
        std::vector<Event> ev = groove(Cs3, 0);
        for (auto& e : ev) if (e.vel < 0.9f) { e.hz = noteHz(Ds2); }
        render(dir, "P01_brummtopf_two_registers", {drum(brummtopf())}, ev);
    }
    render(dir, "P02_zambomba", {drum(zambomba())}, groove(A3));
    { Params p = zambomba(); p.pot = 250; p.potq = 1.5f; p.potlevel = 6; p.release = 60.0f / 190.0f;
      render(dir, "P03_zambomba_grave", {drum(p)}, groove(Fs2)); }
    {
        std::vector<Event> ev;
        for (int i = 0; i < 6; ++i) ev.push_back({0.3 + i * 1.0, 0, noteHz(i % 2 ? E2 : C2), 0.9f});
        render(dir, "P04_putipu", {drum(putipu())}, ev);
    }
    render(dir, "P05_furruco", {drum(furruco())}, pulls(Cs2 - 1 + 1, 8, 0.6));
    {
        std::vector<Event> ev = {{0.3, 0, noteHz(B2), 0.9f}, {1.6, 0, noteHz(B2), 0.7f}, {2.9, 0, noteHz(B2), 1.0f}};
        render(dir, "P06_creak", {drum(creak())}, ev);
    }
    {
        std::vector<Event> ev;
        for (int i = 0; i < 5; ++i) ev.push_back({0.3 + i * 0.8, 0, noteHz(Ds4), 0.9f});
        render(dir, "P07_flick", {drum(flick())}, ev);
    }
    render(dir, "P08_buhai_unmeasured_guess", {drum(buhai())}, pulls(Cs2 - 1, 8, 0.75));
    {
        // a small kit: fanfrnoch low (two hands), fanfrnoch high, brummtopf, cuica
        std::vector<Event> ev = groove(B2, 0, 110);
        double e8 = 60.0 / 110.0 / 2.0;
        for (int i = 0; i < 32; i += 4) ev.push_back({0.3 + (i + 2) * e8, 1, noteHz(A3 + 2), 0.6f});
        for (int i = 0; i < 32; i += 8) ev.push_back({0.3 + (i + 7) * e8, 2, noteHz(F4), 0.7f});
        Params hi = fanfrnoch(); hi.length = 120; hi.release = 0.15f;
        render(dir, "P09_kit_fanfrnoch_low_high_cuica", {drum(fanfrnoch()), drum(hi, true, 5), drum(cuica(), true, 6)}, ev);
    }
    return 0;
}
