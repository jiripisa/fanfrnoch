// Params.cpp - the parameter table, the sections and the programs of the Fanfrnoch engine.
//
// The programs are the prototype's (.planning/research/spike/fanfrnoch_spike.cpp), in engine units.

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
const char* const kStrokeNames[kNumStrokes] = { "Out", "In", "Alternate" };
const char* const kKeyUpNames[kNumKeyUps] = { "Ring", "Damp" };
const char* const kCurveNames[kNumCurves] = { "Glide", "Line", "There and Back", "Step" };
const char* const kLfoStartNames[kNumLfoStarts] = { "Hit", "Free" };

Param floatParam(const char* id, const char* name, float min, float max, float def, const char* unit, int decimals)
{
    return Param{ id, name, unit, FANFRNOCH_KIND_FLOAT, min, max, def, false, decimals };
}
Param logParam(const char* id, const char* name, float min, float max, float def, const char* unit, int decimals)
{
    return Param{ id, name, unit, FANFRNOCH_KIND_FLOAT, min, max, def, true, decimals };
}
Param intParam(const char* id, const char* name, int min, int max, int def, const char* unit = "")
{
    return Param{ id, name, unit, FANFRNOCH_KIND_INT, (float)min, (float)max, (float)def, false, 0 };
}
Param choiceParam(const char* id, const char* name, int numChoices, int def)
{
    return Param{ id, name, "", FANFRNOCH_KIND_CHOICE, 0.0f, (float)(numChoices - 1), (float)def, false, 0 };
}

const Param kKnobs[kNumKnobs] = {
    logParam   ("ring",        "Ring",         0.3f, 15.0f, 4.0f, "s", 2),
    floatParam ("edge",        "Edge",         3.0f, 40.0f, 18.0f, "", 1),
    floatParam ("offset",      "Offset",       -2.0f, 2.0f, 0.2f, "", 2),
    floatParam ("body",        "Body",         -48.0f, 0.0f, -24.0f, "dB", 1),
    floatParam ("buzz",        "Buzz",         0.0f, 100.0f, 40.0f, "%", 0),
    floatParam ("clang",       "Clang",        0.0f, 100.0f, 10.0f, "%", 0),

    floatParam ("velsens",     "Vel Sens",     0.0f, 100.0f, 70.0f, "%", 0),
    choiceParam("stroke",      "Stroke",       kNumStrokes, kStrokeAlternate),
    logParam   ("damp",        "Damp",         2.0f, 80.0f, 10.0f, "ms", 0),
    choiceParam("keyup",       "Key Up",       kNumKeyUps, kKeyUpRing),
    floatParam ("vary",        "Vary",         0.0f, 100.0f, 20.0f, "%", 0),

    logParam   ("vowel",       "Vowel",        500.0f, 3300.0f, 800.0f, "Hz", -1),
    floatParam ("sweep",       "Sweep",        -24.0f, 24.0f, 14.0f, "st", 0),
    logParam   ("sweeptime",   "Sweep Time",   10.0f, 2000.0f, 160.0f, "ms", 0),
    choiceParam("curve",       "Curve",        kNumCurves, kCurveGlide),
    floatParam ("reso",        "Reso",         4.0f, 40.0f, 15.0f, "", 1),
    floatParam ("throat",      "Throat",       -30.0f, 0.0f, -10.0f, "dB", 1),
    logParam   ("throattune",  "Throat Tune",  250.0f, 700.0f, 430.0f, "Hz", -1),
    floatParam ("open",        "Open",         0.0f, 100.0f, 30.0f, "%", 0),
    floatParam ("close",       "Close",        0.0f, 100.0f, 0.0f, "%", 0),

    floatParam ("breath",      "Breath",       -100.0f, 100.0f, 30.0f, "%", 0),
    floatParam ("puff",        "Puff",         0.0f, 100.0f, 30.0f, "%", 0),
    logParam   ("pufftime",    "Puff Time",    20.0f, 1000.0f, 120.0f, "ms", 0),
    floatParam ("air",         "Air",          0.0f, 100.0f, 10.0f, "%", 0),

    floatParam ("volume",      "Volume",       -40.0f, 6.0f, 0.0f, "dB", 1),
    floatParam ("pan",         "Pan",          -100.0f, 100.0f, 0.0f, "%", 0),
    floatParam ("tune",        "Tune",         -100.0f, 100.0f, 0.0f, "ct", 0),
    intParam   ("octave",      "Octave",       -2, 2, 0),
    intParam   ("bendvowel",   "Bend>Vowel",   0, 24, 12, "st"),
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
        case kStroke:    return pick(kStrokeNames, kNumStrokes);
        case kKeyUp:     return pick(kKeyUpNames, kNumKeyUps);
        case kCurve:     return pick(kCurveNames, kNumCurves);
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
        { "Reed",   { kRing, kEdge, kOffset, kBody, kBuzz, kClang } },
        { "Stroke", { kVelSens, kStroke, kDamp, kKeyUp, kVary } },
        { "Mouth",  { kVowel, kSweep, kSweepTime, kCurve, kReso, kThroat, kThroatTune, kOpen, kClose } },
        { "Breath", { kBreath, kPuff, kPuffTime, kAir } },
        { "Master", { kVolume, kPan, kTune, kOctave, kBendVowel, kLfoStart, kLfo1Rate, kLfo1Shape, kLfo2Rate, kLfo2Shape } },
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
// Built-in programs: other jaw harps, as the prototype tuned them by ear. Fanfrnoch is the
// defaults.
// ---------------------------------------------------------------------------------------------
const std::vector<Program>& programs()
{
    static const std::vector<Program> table = {
        makeProgram("Fanfrnoch",   {}),
        // A long, calm ring with the mouth held still: the Alpine Maultrommel.
        makeProgram("Molln",    {{kRing, 7.5f}, {kSweep, 0}, {kVowel, 1050}, {kReso, 25}, {kOpen, 0}, {kOffset, 0}}),
        // The Siberian khomus: buzzing, with a slow turn of the mouth there and back.
        makeProgram("Khomus",   {{kRing, 8}, {kEdge, 26}, {kBuzz, 70}, {kCurve, (float)kCurveThereAndBack}, {kSweep, 12}, {kSweepTime, 400}}),
        // The short Indian morsing: a quick twang, a puff of breath and a closing mouth.
        makeProgram("Morsing",  {{kRing, 1}, {kEdge, 26}, {kSweepTime, 60}, {kPuff, 80}, {kClose, 40}, {kDamp, 5}}),
        // The Vietnamese bamboo harp, plucked outward only, with its open, airy mouth.
        makeProgram("Đàn Môi",  {{kClang, 0}, {kOpen, 60}, {kAir, 30}, {kReso, 10}, {kRing, 3}, {kStroke, (float)kStrokeOut}}),
        // A thin, bright, clanging bamboo tongue.
        makeProgram("Bamboo",   {{kRing, 1}, {kEdge, 7}, {kClang, 60}, {kBuzz, 15}, {kReso, 8}}),
        // The Indonesian genggong: short and clangy, the mouth wide open.
        makeProgram("Genggong", {{kRing, 0.8f}, {kEdge, 9}, {kClang, 40}, {kOpen, 100}}),
    };
    return table;
}

// The octave belongs to the player's hands, not to the sound.
bool programSets(int param) { return param != kOctave; }

// ---------------------------------------------------------------------------------------------
// The default kit, from the prototype's overlapping kit (fanfrnoch_spike.cpp:376-388): pads 1-2 are
// one harp, the second ringing short; the other programs each at a pitch of their own. Pads
// 9-16 repeat pads 1-8 a fifth higher, groups 1-4 becoming 5-8.
// ---------------------------------------------------------------------------------------------
namespace {

constexpr KitPad kKitLow[FANFRNOCH_NUM_PADS / 2] = {
    { kFanfrnoch,   36, 1, {} },
    { kFanfrnoch,   36, 1, { { kRing, 0.6f } } },
    { kBamboo,   39, 0, {} },
    { kMolln,    43, 2, {} },
    { kMorsing,  48, 3, {} },
    { kKhomus,   38, 4, {} },
    { kDanMoi,   39, 0, {} },
    { kGenggong, 41, 0, {} },
};

constexpr std::array<KitPad, FANFRNOCH_NUM_PADS> makeDefaultKit()
{
    std::array<KitPad, FANFRNOCH_NUM_PADS> kit{};
    constexpr int half = FANFRNOCH_NUM_PADS / 2;
    for (int pad = 0; pad < half; ++pad)
    {
        kit[(size_t)pad] = kKitLow[pad];
        KitPad high = kKitLow[pad];
        high.note += 7;
        if (high.group != 0) high.group += 4;
        kit[(size_t)(pad + half)] = high;
    }
    return kit;
}

} // namespace

const std::array<KitPad, FANFRNOCH_NUM_PADS> kDefaultKit = makeDefaultKit();

} // namespace fanfrnoch
