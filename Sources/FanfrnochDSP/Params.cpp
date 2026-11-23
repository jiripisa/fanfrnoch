// Params.cpp - the parameter table, the sections and the programs of the Fanfrnoch engine.
//
// The defaults and the programs are the prototype's (.planning/research/spike/fanfrnoch_spike.cpp),
// in engine units.

// A product and a sum stay two roundings. An optimised build would otherwise fuse them into one
// multiply-add where a debug build does not, and the two builds would render different last
// bits: the engine's sound must be the same in both, and the same as the references it is
// tested against.
#pragma clang fp contract(off)

#include "Params.h"

#include <cstdio>
#include <initializer_list>

namespace fanfrnoch {

namespace {

const char* const kLfoShapeNames[kNumLfoShapes] = { "Sine", "Triangle", "Ramp Up", "Ramp Down", "Square", "Steps", "Wander" };
const char* const kKeyUpNames[kNumKeyUps] = { "Ignore", "Stop" };
const char* const kDrumNames[kNumDrumChoices] = { "One", "Many" };
const char* const kLfoStartNames[kNumLfoStarts] = { "Hit", "Free" };

Param floatParam(const char* id, const char* name, float min, float max, float def, const char* unit, int decimals)
{
    return Param{ id, name, unit, FANFRNOCH_KIND_FLOAT, min, max, def, false, decimals };
}
Param logParam(const char* id, const char* name, float min, float max, float def, const char* unit, int decimals)
{
    return Param{ id, name, unit, FANFRNOCH_KIND_FLOAT, min, max, def, true, decimals };
}
// A level whose bottom is Off: the prototype's -200 dB.
Param levelParam(const char* id, const char* name, float min, float max, float def)
{
    return Param{ id, name, "dB", FANFRNOCH_KIND_FLOAT, min, max, def, false, 1, true };
}
Param intParam(const char* id, const char* name, int min, int max, int def, const char* unit = "")
{
    return Param{ id, name, unit, FANFRNOCH_KIND_INT, (float)min, (float)max, (float)def, false, 0 };
}
Param choiceParam(const char* id, const char* name, int numChoices, int def)
{
    return Param{ id, name, "", FANFRNOCH_KIND_CHOICE, 0.0f, (float)(numChoices - 1), (float)def, false, 0 };
}

// The defaults are the prototype's Params (fanfrnoch_spike.cpp:33-69). Its "off" levels (-200 dB)
// are the bottom of the knob.
const Param kKnobs[kNumKnobs] = {
    logParam   ("attack",      "Attack",       5.0f, 400.0f, 42.0f, "ms", 0),
    floatParam ("length",      "Length",       0.0f, 2000.0f, 230.0f, "ms", 0),
    logParam   ("release",     "Release",      0.03f, 3.0f, 0.30f, "s", 2),
    floatParam ("damp",        "Damp",         0.0f, 100.0f, 0.0f, "%", 0),
    choiceParam("keyup",       "Key Up",       kNumKeyUps, kKeyUpIgnore),
    floatParam ("velsens",     "Vel Sens",     0.0f, 100.0f, 70.0f, "%", 0),
    floatParam ("vary",        "Vary",         0.0f, 100.0f, 20.0f, "%", 0),

    floatParam ("alternate",   "Alternate",    0.0f, 12.0f, 2.0f, "dB", 1),
    floatParam ("alttune",     "Alt Tune",     -100.0f, 100.0f, 10.0f, "ct", 0),

    floatParam ("scoop",       "Scoop",        0.0f, 12.0f, 0.0f, "st", 1),
    logParam   ("scooptime",   "Scoop Time",   10.0f, 300.0f, 80.0f, "ms", 0),
    floatParam ("drift",       "Drift",        -3.0f, 3.0f, -0.8f, "st", 2),
    floatParam ("drop",        "Drop",         0.0f, 2.0f, 0.0f, "st", 2),
    floatParam ("wobble",      "Wobble",       0.0f, 60.0f, 20.0f, "ct", 0),
    floatParam ("jump",        "Jump",         0.0f, 100.0f, 0.0f, "%", 0),
    floatParam ("jumpratio",   "Jump Ratio",   1.1f, 2.5f, 1.40f, "", 2),
    floatParam ("velpitch",    "Vel>Pitch",    0.0f, 100.0f, 0.0f, "ct", 0),

    floatParam ("stick",       "Stick",        0.50f, 0.95f, 0.88f, "", 2),
    floatParam ("stickvel",    "Stick>Level",  0.0f, 0.10f, 0.03f, "", 3),
    floatParam ("split",       "Split",        0.0f, 100.0f, 0.0f, "%", 0),
    floatParam ("creak",       "Creak",        0.0f, 100.0f, 0.0f, "%", 0),
    logParam   ("creakrate",   "Creak Rate",   4.0f, 40.0f, 14.0f, "Hz", -1),
    logParam   ("creakring",   "Creak Ring",   10.0f, 100.0f, 40.0f, "ms", 0),

    logParam   ("pot",         "Pot",          150.0f, 1500.0f, 500.0f, "Hz", -1),
    logParam   ("potq",        "Pot Q",        1.0f, 20.0f, 4.0f, "", 1),
    levelParam ("potlevel",    "Pot Level",    -40.0f, 18.0f, -40.0f),
    logParam   ("skin",        "Skin",         100.0f, 1500.0f, 306.0f, "Hz", -1),
    logParam   ("skinq",       "Skin Q",       1.0f, 40.0f, 10.0f, "", 1),
    levelParam ("skinlevel",   "Skin Level",   -40.0f, 6.0f, -40.0f),
    floatParam ("track",       "Track",        0.0f, 100.0f, 0.0f, "%", 0),

    levelParam ("rub",         "Rub",          -40.0f, 0.0f, -10.0f),
    floatParam ("scrape",      "Scrape",       0.0f, 100.0f, 10.0f, "%", 0),
    floatParam ("shimmer",     "Shimmer",      0.0f, 3.0f, 0.7f, "dB", 1),

    floatParam ("volume",      "Volume",       -40.0f, 6.0f, 0.0f, "dB", 1),
    floatParam ("pan",         "Pan",          -100.0f, 100.0f, 0.0f, "%", 0),
    floatParam ("tune",        "Tune",         -100.0f, 100.0f, 0.0f, "ct", 0),
    intParam   ("octave",      "Octave",       -2, 2, 0),
    intParam   ("bendup",      "Bend Up",      0, 24, 12, "st"),
    intParam   ("benddown",    "Bend Down",    0, 12, 2, "st"),
    choiceParam("drum",        "Drum",         kNumDrumChoices, kDrumOne),
    choiceParam("lfostart",    "LFO Start",    kNumLfoStarts, kLfoStartHit),
    logParam   ("lfo1rate",    "LFO 1 Rate",   0.02f, 20.0f, 6.0f, "Hz", -1),
    choiceParam("lfo1shape",   "LFO 1 Shape",  kNumLfoShapes, kLfoSine),
    logParam   ("lfo2rate",    "LFO 2 Rate",   0.02f, 20.0f, 2.0f, "Hz", -1),
    choiceParam("lfo2shape",   "LFO 2 Shape",  kNumLfoShapes, kLfoSine),
};

// The amounts take their names from their knob. No amount is on at rest: the instrument comes
// plain and the player or a program sets the movement.
char amountIds[kNumLfoAmounts + kNumVelAmounts][24], amountNames[kNumLfoAmounts + kNumVelAmounts][40];

const Param* makeParams()
{
    static Param table[kNumParams];
    for (int i = 0; i < kNumKnobs; ++i) table[i] = kKnobs[i];
    for (int lfo = 0; lfo < kNumLfos; ++lfo)
        for (int t = 0; t < kNumLfoTargets; ++t)
        {
            const int slot = lfo * kNumLfoTargets + t;
            std::snprintf(amountIds[slot], sizeof amountIds[slot], "lfo%d%s", lfo + 1, kKnobs[kLfoTargets[t]].id);
            std::snprintf(amountNames[slot], sizeof amountNames[slot], "LFO %d>%s", lfo + 1, kKnobs[kLfoTargets[t]].name);
            table[kNumKnobs + slot] = floatParam(amountIds[slot], amountNames[slot], -100.0f, 100.0f, 0.0f, "%", 0);
        }
    for (int t = 0; t < kNumVelTargets; ++t)
    {
        const int slot = kNumLfoAmounts + t;
        std::snprintf(amountIds[slot], sizeof amountIds[slot], "vel%s", kKnobs[kVelTargets[t]].id);
        std::snprintf(amountNames[slot], sizeof amountNames[slot], "VEL>%s", kKnobs[kVelTargets[t]].name);
        table[kNumKnobs + slot] = floatParam(amountIds[slot], amountNames[slot], -100.0f, 100.0f, 0.0f, "%", 0);
    }
    return table;
}

Program makeProgram(const char* name, std::initializer_list<Override> overrides)
{
    Program p; p.name = name;
    for (int i = 0; i < kNumParams; ++i) p.values[i] = param(i).def;
    for (const Override& o : overrides) p.values[o.param] = o.value;
    return p;
}

} // namespace

const Param& param(int index)
{
    static const Param* const table = makeParams();
    return table[index];
}

const char* choiceName(int index, int choice)
{
    const auto pick = [choice](const char* const* names, int n) { return names[std::clamp(choice, 0, n - 1)]; };
    switch (index)
    {
        case kKeyUp:     return pick(kKeyUpNames, kNumKeyUps);
        case kDrum:      return pick(kDrumNames, kNumDrumChoices);
        case kLfoStart:  return pick(kLfoStartNames, kNumLfoStarts);
        case kLfo1Shape:
        case kLfo2Shape: return pick(kLfoShapeNames, kNumLfoShapes);
        default:         return "";
    }
}

// ---------------------------------------------------------------------------------------------
// Sections: the groups the knobs are shown in (the app's panels, the Audio Unit's parameter
// groups) and the order inside each. Every knob belongs to exactly one section; the amounts to
// none.
// ---------------------------------------------------------------------------------------------
const std::vector<Section>& sections()
{
    static const std::vector<Section> table = {
        { "Stroke",   { kAttack, kLength, kRelease, kDamp, kKeyUp, kVelSens, kVary } },
        { "Hands",    { kAlternate, kAltTune } },
        { "Pitch",    { kScoop, kScoopTime, kDrift, kDrop, kWobble, kJump, kJumpRatio, kVelPitch } },
        { "Friction", { kStick, kStickVel, kSplit, kCreak, kCreakRate, kCreakRing } },
        { "Body",     { kPot, kPotQ, kPotLevel, kSkin, kSkinQ, kSkinLevel, kTrack } },
        { "Noise",    { kRub, kScrape, kShimmer } },
        { "Master",   { kVolume, kPan, kTune, kOctave, kBendUp, kBendDown, kDrum, kLfoStart, kLfo1Rate, kLfo1Shape,
                        kLfo2Rate, kLfo2Shape } },
    };
    return table;
}

int sectionOf(int param)
{
    for (size_t s = 0; s < sections().size(); ++s)
        for (int p : sections()[s].params) if (p == param) return (int)s;
    return -1;
}

// ---------------------------------------------------------------------------------------------
// Built-in programs: the friction drum and its relatives, as the prototype's program functions
// set them (fanfrnoch_spike.cpp:432-506, and the group render's upper drum, :519). Fanfrnoch is
// the defaults. The prototype's percent knobs are fractions; here they are percent.
//
// The prototype normalised every render, so it set no levels. A program whose full-velocity
// stroke peaks more than 3 dB above the default's (the median of 12 strokes at 48 kHz) is turned
// down by that much with Volume, rounded to 0.5 dB, so that no program drives the limiter: the
// quieter ones keep their softness (a flick is a light touch).
// ---------------------------------------------------------------------------------------------
namespace {

const std::initializer_list<Override> kZambombaValues = {
    {kAttack, 31}, {kLength, 100}, {kRelease, 60.0f / 440.0f}, {kStick, 0.80f}, {kSkin, 306}, {kSkinLevel, -12},
    {kJump, 20}, {kJumpRatio, 1.40f}, {kRub, -14}, {kDrift, 0}, {kDrop, 0.3f},
};

const std::initializer_list<Override> kCuicaValues = {
    {kAttack, 20}, {kLength, 90}, {kRelease, 0.1f}, {kStick, 0.73f}, {kRub, -20}, {kWobble, 8}, {kAlternate, 6},
    {kAltTune, 30}, {kDrop, 0.3f}, {kDrift, 0}, {kScrape, 5},
};

// A program built on another's values, with a few of its own after them.
Program makeProgram(const char* name, std::initializer_list<Override> base, std::initializer_list<Override> overrides)
{
    Program p = makeProgram(name, base);
    for (const Override& o : overrides) p.values[o.param] = o.value;
    return p;
}

} // namespace

const std::vector<Program>& programs()
{
    static const std::vector<Program> table = {
        makeProgram("Fanfrnoch",      {}),
        // The upper drum of the group render (01c): shorter pulls, the hands further apart.
        makeProgram("Fanfrnoch High", {{kLength, 150}, {kAlternate, 3}}),
        // The German Brummtopf: short and dry, with a strong pot.
        makeProgram("Brummtopf",      {{kAttack, 24}, {kLength, 80}, {kRelease, 60.0f / 700.0f}, {kPot, 540}, {kPotQ, 4},
                                       {kPotLevel, 6}, {kRub, -10}, {kWobble, 12}, {kDrift, 0}, {kDrop, 0.25f},
                                       {kVolume, -5.5f}}),
        // The Spanish zambomba: the skin's mode rings, one stroke in five jumps up to it.
        makeProgram("Zambomba",       kZambombaValues),
        // A big zambomba: a low, broad pot and a longer ring.
        makeProgram("Zambomba Grave", kZambombaValues, {{kPot, 250}, {kPotQ, 1.5f}, {kPotLevel, 6}, {kRelease, 60.0f / 190.0f},
                                                           {kVolume, -8.0f}}),
        // The Neapolitan putipù: a slow, deep, rubbing growl through a loud pot.
        makeProgram("Putipù",         {{kAttack, 170}, {kLength, 150}, {kRelease, 1.5f}, {kPot, 470}, {kPotQ, 5},
                                       {kPotLevel, 12}, {kRub, -7}, {kWobble, 8}, {kDrift, -0.5f}}),
        // The Brazilian cuíca: short, clean, high strokes, the two hands far apart.
        makeProgram("Cuíca",          kCuicaValues),
        // The cuíca's whoop: a scoop up to the pitch.
        makeProgram("Cuíca Whoop",    kCuicaValues, {{kScoop, 6.6f}, {kScoopTime, 80}, {kLength, 30}, {kRelease, 0.3f},
                                                     {kAlternate, 0}, {kAltTune, 0}}),
        // The Venezuelan furruco: low, rough, its periods unequal.
        makeProgram("Furruco",        {{kAttack, 70}, {kLength, 200}, {kRelease, 60.0f / 110.0f}, {kSplit, 70},
                                       {kWobble, 45}, {kRub, -5}, {kSkin, 100}, {kSkinQ, 6}, {kSkinLevel, -3}, {kDrift, 0},
                                       {kVolume, -3.5f}}),
        // A creak: the tone broken into separate slips that ring the skin.
        makeProgram("Creak",          {{kCreak, 100}, {kCreakRate, 14}, {kCreakRing, 40}, {kSkin, 300}, {kLength, 900},
                                       {kAttack, 30}, {kRelease, 0.15f}, {kRub, -14}, {kWobble, 0}, {kDrift, 0},
                                       {kScrape, 0}}),
        // A flick: no rubbing at all, only the scrape of a finger.
        makeProgram("Flick",          {{kAttack, 5}, {kLength, 0}, {kRelease, 0.5f}, {kScrape, 60}, {kSplit, 25},
                                       {kStick, 0.75f}, {kRub, -20}, {kDrift, 0}, {kAlternate, 0}}),
        // The Romanian buhai: long, slow, low pulls (a guess: no recording was measured).
        makeProgram("Buhai",          {{kAttack, 80}, {kLength, 500}, {kRelease, 0.4f}, {kRub, -6}, {kWobble, 30},
                                       {kStick, 0.9f}, {kDrift, -1.0f}, {kPot, 250}, {kPotQ, 2}, {kPotLevel, 3},
                                       {kVolume, -9.0f}}),
    };
    return table;
}

// The octave belongs to the player's hands, not to the sound.
bool programSets(int param) { return param != kOctave; }

// ---------------------------------------------------------------------------------------------
// The default kit (instrument design §7): pads 1-2 are one drum played by two hands, 3-4 the
// high drum at two pitches, then the relatives, each group one drum; the last four ring on their
// own (Group Off). The notes: B2 47, G3 55, C4 60, C#3 49, D#2 39, F4 65, G5 79, A3 57, C2 36,
// C#2 37, D#4 63.
// ---------------------------------------------------------------------------------------------
const std::array<KitPad, FANFRNOCH_NUM_PADS> kDefaultKit = {{
    { kFanfrnoch,     47, 1, {} },
    { kFanfrnoch,     47, 1, {} },
    { kFanfrnochHigh, 55, 2, {} },
    { kFanfrnochHigh, 60, 2, {} },
    { kBrummtopf,     49, 3, {} },
    { kBrummtopf,     39, 3, {} },
    { kCuica,         65, 4, {} },
    { kCuica,         79, 4, {} },
    { kCuicaWhoop,    79, 4, {} },
    { kZambomba,      57, 5, { { kJump, 0 } } },
    { kZambomba,      57, 5, { { kJump, 100 } } },
    { kPutipu,        36, 6, {} },
    { kFurruco,       37, 0, {} },
    { kCreakProgram,  47, 0, {} },
    { kFlick,         63, 0, {} },
    { kBuhai,         36, 0, {} },
}};

} // namespace fanfrnoch
