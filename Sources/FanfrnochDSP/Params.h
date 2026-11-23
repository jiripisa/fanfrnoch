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
    // Stroke
    kAttack,        // ms    how slowly the head answers the hand: the onset's rise
    kLength,        // ms    how long the hand rubs
    kRelease,       // s     how long the head rings once the hand stops (T60)
    kDamp,          // %     how much faster the ring dies
    kKeyUp,         // -     what a released key does: let the stroke run its Length or stop the hand
    kVelSens,       // %     how much the velocity changes the loudness
    kVary,          // %     the random difference between one stroke and the next
    // Hands
    kAlternate,     // dB    how much quieter every second stroke of a drum is
    kAltTune,       // ct    how far off the pitch every second stroke of a drum is
    // Pitch
    kScoop,         // st    how far below the pitch a stroke starts
    kScoopTime,     // ms    how long it takes to get there
    kDrift,         // st    how far the pitch moves while the hand rubs
    kDrop,          // st    how far the pitch falls once the hand stops
    kWobble,        // ct    the pitch's random wavering
    kJump,          // %     the share of strokes that end on a higher mode
    kJumpRatio,     // -     how much higher that mode is
    kVelPitch,      // ct    how much higher a full-velocity stroke is
    // Friction
    kStick,         // -     the part of each period the hand sticks: the brightness
    kStickVel,      // -     how much darker the tone grows as the level falls
    kSplit,         // %     how unequal every second period is
    kCreak,         // %     how far the tone breaks into separate slips
    kCreakRate,     // Hz    how many slips a second
    kCreakRing,     // ms    how long each slip rings the head
    // Body
    kPot,           // Hz    the pot's resonance
    kPotQ,          // -     how sharp it is
    kPotLevel,      // dB    how loud it is (the bottom is off)
    kSkin,          // Hz    the skin's resonance
    kSkinQ,         // -     how sharp it is
    kSkinLevel,     // dB    how loud it is (the bottom is off)
    kTrack,         // %     how far both resonances follow the pitch
    // Noise
    kRub,           // dB    the hand's rubbing noise (the bottom is off)
    kScrape,        // %     the scrape at the start of a stroke
    kShimmer,       // dB    the level's random wavering
    // Master
    kVolume,        // dB
    kPan,           // %
    kTune,          // ct    fine tuning
    kOctave,        // -     the octave of the keyboard
    kBendUp,        // st    how far the pitch bend bends up
    kBendDown,      // st    how far the pitch bend bends down
    kDrum,          // -     whether the keyboard plays one drum or a drum per note
    kLfoStart,      // -     whether an LFO restarts with every stroke or runs free
    kLfo1Rate,      // Hz
    kLfo1Shape,     // -
    kLfo2Rate,      // Hz
    kLfo2Shape,     // -
    kNumKnobs,
    // After the knobs come the amounts: first the LFOs' (amountOf), then the velocity's
    // (velAmountOf). An amount says how far that source moves that knob, as a part of the
    // knob's travel.
    kNumLfoAmounts = 22,
    kNumVelAmounts = 36,
    kNumParams = kNumKnobs + kNumLfoAmounts + kNumVelAmounts
};

constexpr int kNumLfos = 2;

// The knobs an LFO can move: the pitch (Tune), the hand's friction, the body and the noise.
constexpr int kLfoTargets[] = { kTune, kStick, kRub, kPot, kPotLevel, kSkinLevel, kWobble, kCreak, kSplit, kVolume, kPan };
constexpr int kNumLfoTargets = (int)(sizeof(kLfoTargets) / sizeof(kLfoTargets[0]));

// The knobs the stroke's velocity can move: every continuous knob of the sound but Vel Sens,
// and Volume, Pan, Tune and the LFOs' rates.
constexpr int kVelTargets[] = { kAttack, kLength, kRelease, kDamp, kVary, kAlternate, kAltTune, kScoop, kScoopTime,
                                kDrift, kDrop, kWobble, kJump, kJumpRatio, kVelPitch, kStick, kStickVel, kSplit, kCreak,
                                kCreakRate, kCreakRing, kPot, kPotQ, kPotLevel, kSkin, kSkinQ, kSkinLevel, kTrack, kRub,
                                kScrape, kShimmer, kVolume, kPan, kTune, kLfo1Rate, kLfo2Rate };
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
// where there is one (73 Attack Time, 72 Release Time, 74 Brightness, 71 Timbre, 2 Breath, 7
// Volume, 10 Pan), and for the others the numbers MIDI leaves undefined (14-31, 85-90, 102-119),
// in the order of the knobs. The amounts have none.
// ---------------------------------------------------------------------------------------------
constexpr int kNoController = -1;

constexpr int kStandardController[kNumKnobs] = {
    73, 14, 72, 15, 16, 17, 18,                 // Stroke: Attack (Attack Time), Length, Release (Release Time), Damp,
                                                //         Key Up, Vel Sens, Vary
    19, 20,                                     // Hands: Alternate, Alt Tune
    21, 22, 23, 24, 25, 26, 27, 28,             // Pitch: Scoop, Scoop Time, Drift, Drop, Wobble, Jump, Jump Ratio, Vel>Pitch
    74, 29, 30, 31, 85, 86,                     // Friction: Stick (Brightness), Stick>Level, Split, Creak, Creak Rate, Creak Ring
    87, 71, 88, 89, 90, 102, 103,               // Body: Pot, Pot Q (Timbre), Pot Level, Skin, Skin Q, Skin Level, Track
    2, 104, 105,                                // Noise: Rub (Breath Controller), Scrape, Shimmer
    7, 10, 106, 107, 108, 109, 110, 111,        // Master: Volume, Pan, Tune, Octave, Bend Up, Bend Down, Drum, LFO Start,
    112, 113, 114, 115,                         //         LFO 1 Rate, LFO 1 Shape, LFO 2 Rate, LFO 2 Shape
};

constexpr int standardController(int param) { return param >= 0 && param < kNumKnobs ? kStandardController[param] : kNoController; }

// Controllers no knob can have: those MIDI gives a meaning of its own (bank select, data entry,
// the sustain pedal, parameter numbers, channel mode: 120 All Sound Off, 121 Reset All
// Controllers, 123 All Notes Off) and the mod wheel, which adds Rub.
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
enum KeyUp { kKeyUpIgnore, kKeyUpStop, kNumKeyUps };
enum Drum { kDrumOne, kDrumMany, kNumDrumChoices };
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
    bool  offAtMin = false;     // the bottom of the travel is Off (a level that is not there)

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

// The whole table: the knobs, the LFO amounts ("lfo1stick", "LFO 1>Stick"), then the velocity
// amounts ("velattack", "VEL>Attack").
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
enum ProgramIndex { kFanfrnoch, kFanfrnochHigh, kBrummtopf, kZambomba, kZambombaGrave, kPutipu, kCuica, kCuicaWhoop,
                    kFurruco, kCreakProgram, kFlick, kBuhai, kNumPrograms };

// One knob set to a plain value; param -1 is no override.
struct Override { int param = -1; float value = 0.0f; };

// The default kit (instrument design §7): what each pad holds when the engine is created or the
// kit is loaded. A pad's set is a program with a few overrides and Octave 0, at a note, in a group
// (0 = Off): the pads of one group are one drum. The kit is a call, to be approved by ear.
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
