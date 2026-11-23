// Params.h - the parameter table of the Fanfrnoch engine: the knobs, the amounts, the sections and
// the programs.
//
// The identifiers and the order are permanent from here on: only ever append.

#pragma once

#include "FanfrnochDSP.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <vector>

namespace fanfrnoch {

// ---------------------------------------------------------------------------------------------
// The knobs, group by group. One set of them is a sound; the keyboard has one and every pad has
// one.
// ---------------------------------------------------------------------------------------------
enum Params
{
    // Reed
    kRing,          // s     how long the tongue rings after a pluck
    kEdge,          // -     how sharply the tongue's tip strikes the frame: the harmonics' reach
    kOffset,        // -     how far the tongue sits off the middle of the gap: the even harmonics
    kBody,          // dB    the level of the reed's own body tone under the twang
    kBuzz,          // %     the rattle of the tongue against the frame
    kClang,         // %     the metallic clang of a hard pluck
    // Stroke
    kVelSens,       // %     how much the velocity changes the loudness
    kStroke,        // -     the direction of the pluck: out, in, or one after the other
    kDamp,          // ms    how fast a finger stops the tongue
    kKeyUp,         // -     what a released key does: let the tongue ring or stop it
    kVary,          // %     the random difference between one pluck and the next
    // Mouth
    kVowel,         // Hz    the formant of the mouth cavity the harmonics pass through
    kSweep,         // st    how far the mouth moves the vowel after a pluck
    kSweepTime,     // ms    how long that movement takes
    kCurve,         // -     the path of that movement
    kReso,          // -     how sharply the mouth cavity resonates
    kThroat,        // dB    the level of the throat's resonance
    kThroatTune,    // Hz    where the throat's resonance stands
    kOpen,          // %     how open the lips are: the brightness of the mouth
    kClose,         // %     how far the lips are closed
    // Breath
    kBreath,        // %     the breath through the instrument (negative: drawn in)
    kPuff,          // %     the burst of breath that goes with a pluck
    kPuffTime,      // ms    how long that burst lasts
    kAir,           // %     the hiss of air in the gap
    // Master
    kVolume,        // dB
    kPan,           // %
    kTune,          // ct    fine tuning
    kOctave,        // -     the octave of the keyboard
    kBendVowel,     // st    how far the pitch bend moves the vowel
    kLfoStart,      // -     whether an LFO restarts with every hit or runs free
    kLfo1Rate,      // Hz
    kLfo1Shape,     // -
    kLfo2Rate,      // Hz
    kLfo2Shape,     // -
    kNumKnobs,
    // After the knobs come the amounts: first the LFOs' (amountOf), then the velocity's
    // (velAmountOf). An amount says how far that source moves that knob, as a part of the
    // knob's travel.
    kNumLfoAmounts = 22,
    kNumVelAmounts = 25,
    kNumParams = kNumKnobs + kNumLfoAmounts + kNumVelAmounts
};

constexpr int kNumLfos = 2;

// The knobs an LFO can move: the continuous ones the mouth, the breath and the reed answer to.
constexpr int kLfoTargets[] = { kVowel, kClose, kBreath, kOpen, kReso, kThroat, kBuzz, kBody, kVolume, kEdge, kOffset };
constexpr int kNumLfoTargets = (int)(sizeof(kLfoTargets) / sizeof(kLfoTargets[0]));

// The knobs the hit's velocity can move: the same, and the times, the pitch and the LFOs' rates.
constexpr int kVelTargets[] = { kRing, kDamp, kEdge, kOffset, kBody, kBuzz, kClang, kVary, kVowel, kSweep, kSweepTime,
                                kReso, kThroat, kThroatTune, kOpen, kClose, kBreath, kPuff, kPuffTime, kAir, kVolume,
                                kPan, kTune, kLfo1Rate, kLfo2Rate };
constexpr int kNumVelTargets = (int)(sizeof(kVelTargets) / sizeof(kVelTargets[0]));

static_assert(kNumLfoAmounts == kNumLfos * kNumLfoTargets, "the LFO amounts do not fill the table");
static_assert(kNumVelAmounts == kNumVelTargets, "the velocity amounts do not fill the table");

// The parameter that says how far LFO `lfo` moves `knob`; -1 when it cannot move it.
constexpr int amountOf(int lfo, int knob)
{
    for (int t = 0; t < kNumLfoTargets; ++t) if (kLfoTargets[t] == knob) return kNumKnobs + lfo * kNumLfoTargets + t;
    return -1;
}

// The parameter that says how far the velocity moves `knob`; -1 when it cannot move it.
constexpr int velAmountOf(int knob)
{
    for (int t = 0; t < kNumVelTargets; ++t) if (kVelTargets[t] == knob) return kNumKnobs + kNumLfoAmounts + t;
    return -1;
}

// ---------------------------------------------------------------------------------------------
// MIDI controllers. Every knob comes with one: the controller General MIDI names for the thing
// where there is one (7 Volume, 10 Pan, 74 Brightness, 71 Timbre, 72 Release Time, 2 Breath, 73
// Attack Time), and for the others the numbers MIDI leaves undefined (14-31, 85-90, 102-119), in
// the order of the knobs. The amounts have none.
// ---------------------------------------------------------------------------------------------
constexpr int kNoController = -1;

constexpr int kStandardController[kNumKnobs] = {
    72, 14, 15, 16, 17, 18,                     // Reed: Ring (Release Time), Edge, Offset, Body, Buzz, Clang
    73, 19, 20, 21, 22,                         // Stroke: Vel Sens (Attack Time), Stroke, Damp, Key Up, Vary
    74, 23, 24, 25, 71, 26, 27, 28, 29,         // Mouth: Vowel (Brightness), Sweep, Sweep Time, Curve, Reso (Timbre),
                                                //        Throat, Throat Tune, Open, Close
    2, 30, 31, 85,                              // Breath: Breath (Breath Controller), Puff, Puff Time, Air
    7, 10, 86, 87, 88, 89, 90, 102, 103, 104,   // Master: Volume, Pan, Tune, Octave, Bend>Vowel, LFO Start,
                                                //         LFO 1 Rate, LFO 1 Shape, LFO 2 Rate, LFO 2 Shape
};

constexpr int standardController(int param) { return param >= 0 && param < kNumKnobs ? kStandardController[param] : kNoController; }

// Controllers no knob can have: those MIDI gives a meaning of its own (bank select, data entry,
// the sustain pedal, parameter numbers, channel mode: 120 All Sound Off, 121 Reset All
// Controllers, 123 All Notes Off) and the mod wheel, which moves Close.
constexpr bool controllerReserved(int cc)
{
    return cc <= 1 || cc == 6 || cc == 32 || cc == 38 || cc == 64 || (cc >= 96 && cc <= 101) || cc >= 120;
}

constexpr bool standardControllersAreSound()
{
    for (int i = 0; i < kNumKnobs; ++i)
    {
        const int cc = kStandardController[i];
        if (cc < 0 || cc > 127 || controllerReserved(cc)) return false;
        for (int j = 0; j < i; ++j) if (kStandardController[j] == cc) return false;
    }
    return true;
}
static_assert(standardControllersAreSound(), "a knob's standard controller is reserved or shared");

// The shapes of an LFO's cycle. Steps takes a new random level each cycle and holds it; Wander
// takes one and moves there smoothly.
enum LfoShape { kLfoSine, kLfoTriangle, kLfoRampUp, kLfoRampDown, kLfoSquare, kLfoSteps, kLfoWander, kNumLfoShapes };
enum Stroke { kStrokeOut, kStrokeIn, kStrokeAlternate, kNumStrokes };
enum KeyUp { kKeyUpRing, kKeyUpDamp, kNumKeyUps };
enum Curve { kCurveGlide, kCurveLine, kCurveThereAndBack, kCurveStep, kNumCurves };
enum LfoStart { kLfoStartHit, kLfoStartFree, kNumLfoStarts };

struct Param
{
    const char* id;
    const char* name;
    const char* unit;
    int   kind;                 // FANFRNOCH_KIND_*
    float min, max, def;
    bool  logarithmic;
    int   decimals;             // for the text of a float; -1 = by size, as a frequency is written

    float toPlain(float norm) const
    {
        norm = std::clamp(norm, 0.0f, 1.0f);
        if (kind == FANFRNOCH_KIND_CHOICE)
        {
            const int n = (int)max + 1;
            return n < 2 ? 0.0f : (float)std::clamp((int)std::lround(norm * (float)(n - 1)), 0, n - 1);
        }
        if (kind == FANFRNOCH_KIND_INT) return std::round(min + norm * (max - min));
        if (logarithmic && min > 0.0f && max > 0.0f) return min * std::pow(max / min, norm);
        return min + (max - min) * norm;
    }

    float toNormalised(float plain) const
    {
        if (kind == FANFRNOCH_KIND_CHOICE)
        {
            const int n = (int)max + 1;
            return n < 2 ? 0.0f : std::clamp(plain / (float)(n - 1), 0.0f, 1.0f);
        }
        if (max == min) return 0.0f;
        plain = std::clamp(plain, std::fmin(min, max), std::fmax(min, max));
        if (kind == FANFRNOCH_KIND_FLOAT && logarithmic && min > 0.0f && max > 0.0f)
            return std::clamp(std::log(plain / min) / std::log(max / min), 0.0f, 1.0f);
        return std::clamp((plain - min) / (max - min), 0.0f, 1.0f);
    }
};

// The whole table: the knobs, the LFO amounts ("lfo1vowel", "LFO 1>Vowel"), then the velocity
// amounts ("velring", "VEL>Ring").
const Param& param(int index);
inline bool validParam(int i) { return i >= 0 && i < kNumParams; }

const char* choiceName(int index, int choice);

struct Section { const char* name; std::vector<int> params; };
const std::vector<Section>& sections();
int sectionOf(int param);

// Built-in programs: the defaults with a few values overridden.
struct Program { const char* name; float values[kNumParams]; };
const std::vector<Program>& programs();
bool programSets(int param);     // false for the knobs a program leaves alone

// The built-in programs, in the order of programs().
enum ProgramIndex { kFanfrnoch, kMolln, kKhomus, kMorsing, kDanMoi, kBamboo, kGenggong, kNumPrograms };

// One knob set to a plain value; param -1 is no override.
struct Override { int param = -1; float value = 0.0f; };

// The default kit (engine design §7): what each pad holds when the engine is created or the kit is
// loaded. A pad's set is a program with a few overrides and Octave 0, at a note, in a mute group
// (0 = Off). The kit is a call, to be approved by ear.
constexpr int kMaxKitOverrides = 4;
struct KitPad
{
    int program;
    int note;
    int group;
    Override overrides[kMaxKitOverrides];
};
extern const std::array<KitPad, FANFRNOCH_NUM_PADS> kDefaultKit;

} // namespace fanfrnoch
