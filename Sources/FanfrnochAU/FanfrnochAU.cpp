// FanfrnochAU.cpp - the Fanfrnoch instrument as an Audio Unit (AUv2 music device).
//
// A thin layer over the sound engine (FanfrnochDSP): it publishes the keyboard set's parameters and
// the built-in programs to the host, forwards MIDI and renders. Audio Unit parameter values are
// the engine's "plain" values (s, Hz, ms, dB, %, an index), so automation and saved host projects
// read naturally. The pads, their notes and groups and the mode are no parameters: the plug-in's
// window sets them on the engine directly (kFanfrnochProperty_Engine), and they are saved with the
// unit's state, as are the MIDI controllers, the pad the window shows and the presets the sets came
// from. Built on Apple's AudioUnitSDK.

#include "FanfrnochAU.h"
#include "FanfrnochDSP.h"

#include <AudioUnitSDK/MusicDeviceBase.h>

#include <algorithm>
#include <atomic>
#include <cstring>
#include <mutex>
#include <vector>

namespace {

// Groups shown by hosts that draw a generic parameter view ("clumps"): the engine's sections,
// the same as the app's panels. Clump 0 means "no group", so section n is clump n + 1.
UInt32 clumpOf(const FanfrnochParamInfo& info) { return static_cast<UInt32>(info.section) + 1; }

AudioUnitParameterUnit unitOf(const FanfrnochParamInfo& info)
{
    if (info.kind == FANFRNOCH_KIND_CHOICE) return kAudioUnitParameterUnit_Indexed;
    if (!std::strcmp(info.unit, "s"))  return kAudioUnitParameterUnit_Seconds;
    if (!std::strcmp(info.unit, "Hz")) return kAudioUnitParameterUnit_Hertz;
    if (!std::strcmp(info.unit, "dB")) return kAudioUnitParameterUnit_Decibels;
    if (!std::strcmp(info.unit, "ms")) return kAudioUnitParameterUnit_Milliseconds;
    if (!std::strcmp(info.unit, "%"))  return kAudioUnitParameterUnit_Percent;
    if (!std::strcmp(info.unit, "st")) return kAudioUnitParameterUnit_RelativeSemiTones;
    if (!std::strcmp(info.unit, "ct")) return kAudioUnitParameterUnit_Cents;
    return kAudioUnitParameterUnit_Generic;
}

// The built-in programs as AUPresets. The table lives for the life of the process.
const std::vector<AUPreset>& factoryPresets()
{
    static const std::vector<AUPreset> presets = [] {
        std::vector<AUPreset> v;
        for (int i = 0; i < fanfrnoch_num_programs(); ++i)
            v.push_back(AUPreset{ i, CFStringCreateWithCString(nullptr, fanfrnoch_program_name(i), kCFStringEncodingUTF8) });
        return v;
    }();
    return presets;
}

// The longest a note can ring: the top of the Ring knob, in seconds.
Float64 longestRing()
{
    for (int i = 0; i < fanfrnoch_num_params(); ++i)
    {
        FanfrnochParamInfo info{};
        fanfrnoch_param_info(i, &info);
        if (!std::strcmp(info.identifier, "ring")) return info.maxValue;
    }
    return 0.0;
}

// The rate fanfrnoch_create() prepares the engine for, before a host sets one.
constexpr Float64 kStartRate = 44100.0;

// The knobs: the parameters that can have a MIDI controller, at the start of the table.
int knobCount()
{
    int knobs = 0;
    while (knobs < fanfrnoch_num_params() && fanfrnoch_standard_controller(knobs) >= 0) ++knobs;
    return knobs;
}

// ----- the pads in the saved state ----------------------------------------------------------
// The base class saves the unit's parameters (the keyboard set). The program the keyboard set
// last loaded, the pads, the mode, the pad the window shows and the presets in use ride along
// under a key of their own:
//   "fanfrnoch-pads": { "mode": int, "keyboardProgram": int, "selectedPad": int (0...15),
//                    "keyboardPreset": string ("" for none),
//                    "pads": [ 16 × { "note": int, "group": int (0 = Off), "program": int,
//                                     "preset": string ("" for none),
//                                     "values": data: Float32 plain values by parameter index } ] }
// The MIDI controllers of the knobs under another:
//   "fanfrnoch-controllers": data: SInt32 per knob in table order, -1 for none

CFStringRef padsKey() { return CFSTR("fanfrnoch-pads"); }
CFStringRef controllersKey() { return CFSTR("fanfrnoch-controllers"); }

void setInt(CFMutableDictionaryRef dict, CFStringRef key, SInt32 value)
{
    CFNumberRef number = CFNumberCreate(nullptr, kCFNumberSInt32Type, &value);
    CFDictionarySetValue(dict, key, number);
    CFRelease(number);
}

// The int under `key`; false if there is none.
bool getInt(CFDictionaryRef dict, CFStringRef key, int& out)
{
    const void* value = CFDictionaryGetValue(dict, key);
    if (!value || CFGetTypeID(value) != CFNumberGetTypeID()) return false;
    SInt32 number = 0;
    if (!CFNumberGetValue(static_cast<CFNumberRef>(value), kCFNumberSInt32Type, &number)) return false;
    out = number;
    return true;
}

// The longest name a preset can have, in characters: FanfrnochCore's PresetLibrary.longestName.
constexpr CFIndex kLongestName = 60;

// "" (no preset), retained.
CFStringRef copyNoName() { return static_cast<CFStringRef>(CFRetain(CFSTR(""))); }

// Whether a name is no longer than a preset's can be. Characters are counted as Swift counts
// them, near enough: composed character sequences, so that "é" written as e + accent is one.
bool fitsAsName(CFStringRef name)
{
    const CFIndex length = CFStringGetLength(name);
    if (length <= kLongestName) return true;          // a character is at least one UTF-16 unit
    CFIndex characters = 0;
    for (CFIndex at = 0; at < length; ++characters)
    {
        if (characters == kLongestName) return false;
        const CFRange character = CFStringGetRangeOfComposedCharactersAtIndex(name, at);
        at = character.location + character.length;
    }
    return true;
}

// A copy of a name from outside the unit; "" (none) for one that is not a string or is longer
// than a preset's name can be.
CFStringRef copyName(CFTypeRef value)
{
    if (!value || CFGetTypeID(value) != CFStringGetTypeID() || !fitsAsName(static_cast<CFStringRef>(value))) return copyNoName();
    return CFStringCreateCopy(nullptr, static_cast<CFStringRef>(value));
}

// The name under `key`, as copyName gives it.
CFStringRef copyName(CFDictionaryRef dict, CFStringRef key) { return copyName(CFDictionaryGetValue(dict, key)); }

// A copy of what the window gives as the presets in use: an array of one string per set, nothing
// else; nullptr if it is not that. A name longer than a preset's can be counts as none.
CFArrayRef copyNames(CFTypeRef value)
{
    if (!value || CFGetTypeID(value) != CFArrayGetTypeID()) return nullptr;
    const auto array = static_cast<CFArrayRef>(value);
    if (CFArrayGetCount(array) != FANFRNOCH_NUM_SETS) return nullptr;
    for (CFIndex i = 0; i < FANFRNOCH_NUM_SETS; ++i)
    {
        const void* name = CFArrayGetValueAtIndex(array, i);
        if (!name || CFGetTypeID(name) != CFStringGetTypeID()) return nullptr;
    }
    CFMutableArrayRef copy = CFArrayCreateMutable(nullptr, FANFRNOCH_NUM_SETS, &kCFTypeArrayCallBacks);
    for (CFIndex i = 0; i < FANFRNOCH_NUM_SETS; ++i)
    {
        CFStringRef name = copyName(CFArrayGetValueAtIndex(array, i));
        CFArrayAppendValue(copy, name);
        CFRelease(name);
    }
    return copy;
}

CFDictionaryRef copyPad(FanfrnochEngine* engine, int pad, CFStringRef preset)
{
    const int set = pad + 1;
    CFMutableDictionaryRef dict = CFDictionaryCreateMutable(nullptr, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(dict, CFSTR("preset"), preset);
    setInt(dict, CFSTR("note"), fanfrnoch_pad_note(engine, pad));
    setInt(dict, CFSTR("group"), fanfrnoch_pad_group(engine, pad));
    setInt(dict, CFSTR("program"), fanfrnoch_get_program(engine, set));
    std::vector<Float32> values(static_cast<size_t>(fanfrnoch_num_params()));
    for (size_t i = 0; i < values.size(); ++i) values[i] = fanfrnoch_get_plain(engine, set, static_cast<int>(i));
    CFDataRef data = CFDataCreate(nullptr, reinterpret_cast<const UInt8*>(values.data()),
                                  static_cast<CFIndex>(values.size() * sizeof(Float32)));
    CFDictionarySetValue(dict, CFSTR("values"), data);
    CFRelease(data);
    return dict;
}

// What is missing from a saved pad stays as it is. A list of values from a version with fewer
// parameters covers the first of them; the table only ever grows at its end.
void restorePad(FanfrnochEngine* engine, int pad, CFDictionaryRef dict)
{
    const int set = pad + 1;
    int number = 0;
    if (getInt(dict, CFSTR("note"), number)) fanfrnoch_set_pad_note(engine, pad, number);
    if (getInt(dict, CFSTR("group"), number)) fanfrnoch_set_pad_group(engine, pad, number);

    const int count = fanfrnoch_num_params();
    const void* stored = CFDictionaryGetValue(dict, CFSTR("values"));
    CFDataRef data = stored && CFGetTypeID(stored) == CFDataGetTypeID() ? static_cast<CFDataRef>(stored) : nullptr;
    const int saved = data ? std::min(count, static_cast<int>(CFDataGetLength(data) / static_cast<CFIndex>(sizeof(Float32)))) : 0;

    // Loading a program overwrites the whole set: the knobs the state has no value for are
    // taken away first and put back after.
    int program = 0;
    if (getInt(dict, CFSTR("program"), program) && program != fanfrnoch_get_program(engine, set))
    {
        std::vector<float> kept(static_cast<size_t>(count));
        for (int i = saved; i < count; ++i) kept[static_cast<size_t>(i)] = fanfrnoch_get_normalised(engine, set, i);
        fanfrnoch_set_program(engine, set, program);
        for (int i = saved; i < count; ++i) fanfrnoch_set_normalised(engine, set, i, kept[static_cast<size_t>(i)]);
    }
    const UInt8* bytes = data ? CFDataGetBytePtr(data) : nullptr;
    for (int i = 0; i < saved; ++i)
    {
        Float32 value = 0;
        std::memcpy(&value, bytes + static_cast<size_t>(i) * sizeof(Float32), sizeof value);   // CFData need not be aligned
        fanfrnoch_set_plain(engine, set, i, value);
    }
}

} // namespace

class FanfrnochAU : public ausdk::MusicDeviceBase {
    using Base = ausdk::MusicDeviceBase;

public:
    explicit FanfrnochAU(AudioComponentInstance instance)
        : Base{ instance, 0, 1 }, engine_(fanfrnoch_create()), knobs_(knobCount()), tail_(longestRing())
    {
        CreateElements();
        const int count = fanfrnoch_num_params();
        Globals()->UseIndexedParameters(static_cast<UInt32>(count));
        applied_.resize(static_cast<size_t>(count));
        heard_.resize(static_cast<size_t>(count));
        for (int i = 0; i < count; ++i)
        {
            FanfrnochParamInfo info{};
            fanfrnoch_param_info(i, &info);
            Globals()->SetParameter(static_cast<AudioUnitParameterID>(i), info.defaultValue);
            applied_[static_cast<size_t>(i)] = info.defaultValue;
            heard_[static_cast<size_t>(i)] = fanfrnoch_get_plain(engine_, FANFRNOCH_KEYBOARD_SET, i);
        }
        SetAFactoryPresetAsCurrent(factoryPresets().front());
        // A host may ask for the latency before it initialises the unit.
        latency_.store(fanfrnoch_latency(engine_) / kStartRate, std::memory_order_relaxed);

        CFMutableArrayRef names = CFArrayCreateMutable(nullptr, FANFRNOCH_NUM_SETS, &kCFTypeArrayCallBacks);
        for (int set = 0; set < FANFRNOCH_NUM_SETS; ++set) CFArrayAppendValue(names, CFSTR(""));
        presetNames_ = ausdk::Owned<CFArrayRef>::from_create(names);   // nobody else can reach the unit yet
    }

    ~FanfrnochAU() override { fanfrnoch_destroy(engine_); }

    // ----- formats --------------------------------------------------------------------------
    bool StreamFormatWritable(AudioUnitScope, AudioUnitElement) override { return !IsInitialized(); }
    bool CanScheduleParameters() const noexcept AUSDK_RTSAFE override { return false; }

    UInt32 SupportedNumChannels(const AUChannelInfo** outInfo) override
    {
        static const AUChannelInfo configurations[] = { { 0, 2 }, { 0, 1 } };   // no input; stereo or mono out
        if (outInfo) *outInfo = configurations;
        return 2;
    }

    OSStatus Initialize() override
    {
        const AudioStreamBasicDescription& format = Output(0).GetStreamFormat();
        if (format.mChannelsPerFrame < 1 || format.mChannelsPerFrame > 2) return kAudioUnitErr_FormatNotSupported;
        fanfrnoch_prepare(engine_, format.mSampleRate);
        const Float64 latency = format.mSampleRate > 0 ? fanfrnoch_latency(engine_) / format.mSampleRate : 0.0;
        if (latency != latency_.load(std::memory_order_relaxed))
        {
            latency_.store(latency, std::memory_order_relaxed);
            PropertyChanged(kAudioUnitProperty_Latency, kAudioUnitScope_Global, 0);
        }
        // A mono output gets both sides mixed: the engine renders stereo into these first. Made
        // here, never while rendering; the host cannot raise the frames per slice until the
        // unit is uninitialised.
        const size_t scratch = format.mChannelsPerFrame == 1 ? GetMaxFramesPerSlice() : 0;
        scratchLeft_.assign(scratch, 0.0f);
        scratchRight_.assign(scratch, 0.0f);
        return noErr;
    }

    OSStatus Reset(AudioUnitScope scope, AudioUnitElement element) override
    {
        fanfrnoch_request_reset(engine_);     // left to the render thread: a host may reset while it renders
        return Base::Reset(scope, element);
    }

    // Output lags MIDI by the engine's decimator below 88.2 kHz; a note rings at most as long as
    // the longest Ring.
    Float64 GetLatency() AUSDK_RTSAFE override { return latency_.load(std::memory_order_relaxed); }
    bool SupportsTail() AUSDK_RTSAFE override { return true; }
    Float64 GetTailTime() AUSDK_RTSAFE override { return tail_; }

    // ----- properties -----------------------------------------------------------------------
    // A host asks for the plug-in's own window through the CocoaUI property: the bundle and the
    // name of a class in it that makes the view (FanfrnochAUViewFactory). Without the component
    // bundle (the unit registered in a process by hand) there is none, and the host shows its
    // generic parameter view. The unit's own properties are described in FanfrnochAU.h.
    OSStatus GetPropertyInfo(AudioUnitPropertyID id, AudioUnitScope scope, AudioUnitElement element,
                             UInt32& outDataSize, bool& outWritable) override
    {
        if (scope == kAudioUnitScope_Global)
        {
            switch (id)
            {
                case kAudioUnitProperty_CocoaUI:
                    if (!CFBundleGetBundleWithIdentifier(CFSTR(FANFRNOCH_AU_BUNDLE_ID))) return kAudioUnitErr_InvalidProperty;
                    outDataSize = sizeof(AudioUnitCocoaViewInfo);
                    outWritable = false;
                    return noErr;
                case kFanfrnochProperty_Engine:
                    outDataSize = sizeof(FanfrnochEngine*);
                    outWritable = false;
                    return noErr;
                case kFanfrnochProperty_StateChanged:
                case kFanfrnochProperty_SelectedPad:
                    outDataSize = sizeof(UInt32);
                    outWritable = true;
                    return noErr;
                case kFanfrnochProperty_PresetNames:
                    outDataSize = sizeof(CFArrayRef);
                    outWritable = true;
                    return noErr;
                default:
                    break;
            }
        }
        return Base::GetPropertyInfo(id, scope, element, outDataSize, outWritable);
    }

    OSStatus GetProperty(AudioUnitPropertyID id, AudioUnitScope scope, AudioUnitElement element, void* outData) override
    {
        if (scope == kAudioUnitScope_Global)
        {
            switch (id)
            {
                case kAudioUnitProperty_CocoaUI:
                {
                    CFBundleRef bundle = CFBundleGetBundleWithIdentifier(CFSTR(FANFRNOCH_AU_BUNDLE_ID));
                    if (!bundle) return kAudioUnitErr_InvalidProperty;
                    auto* info = static_cast<AudioUnitCocoaViewInfo*>(outData);
                    info->mCocoaAUViewBundleLocation = CFBundleCopyBundleURL(bundle);       // the host releases both
                    info->mCocoaAUViewClass[0] = CFStringCreateWithCString(nullptr, FANFRNOCH_AU_VIEW_CLASS, kCFStringEncodingUTF8);
                    return noErr;
                }
                case kFanfrnochProperty_Engine:
                    *static_cast<FanfrnochEngine**>(outData) = engine_;
                    return noErr;
                case kFanfrnochProperty_StateChanged:
                    return kAudioUnitErr_InvalidPropertyValue;     // written, never read
                case kFanfrnochProperty_SelectedPad:
                    *static_cast<UInt32*>(outData) = selectedPad_.load(std::memory_order_relaxed);
                    return noErr;
                case kFanfrnochProperty_PresetNames:
                    *static_cast<CFArrayRef*>(outData) = copyPresetNames();   // the caller releases it
                    return noErr;
                default:
                    break;
            }
        }
        return Base::GetProperty(id, scope, element, outData);
    }

    OSStatus SetProperty(AudioUnitPropertyID id, AudioUnitScope scope, AudioUnitElement element,
                         const void* inData, UInt32 inDataSize) override
    {
        if (scope == kAudioUnitScope_Global)
        {
            if (id == kFanfrnochProperty_Engine) return kAudioUnitErr_PropertyNotWritable;
            if (id == kFanfrnochProperty_StateChanged)
            {
                if (inDataSize != sizeof(UInt32)) return kAudioUnitErr_InvalidPropertyValue;
                PropertyChanged(kAudioUnitProperty_ClassInfo, kAudioUnitScope_Global, 0);
                return noErr;
            }
            if (id == kFanfrnochProperty_SelectedPad)
            {
                if (inDataSize != sizeof(UInt32)) return kAudioUnitErr_InvalidPropertyValue;
                const UInt32 pad = *static_cast<const UInt32*>(inData);
                if (pad >= FANFRNOCH_NUM_PADS) return kAudioUnitErr_InvalidPropertyValue;
                selectedPad_.store(pad, std::memory_order_relaxed);
                return noErr;
            }
            if (id == kFanfrnochProperty_PresetNames)
            {
                if (inDataSize != sizeof(CFArrayRef)) return kAudioUnitErr_InvalidPropertyValue;
                CFArrayRef names = copyNames(*static_cast<const CFTypeRef*>(inData));
                if (!names) return kAudioUnitErr_InvalidPropertyValue;
                replacePresetNames(names);
                return noErr;
            }
        }
        return Base::SetProperty(id, scope, element, inData, inDataSize);
    }

    // ----- saved state ----------------------------------------------------------------------
    OSStatus SaveState(CFPropertyListRef* outData) override
    {
        const OSStatus status = Base::SaveState(outData);
        if (status != noErr || !outData || !*outData || CFGetTypeID(*outData) != CFDictionaryGetTypeID()) return status;
        // The base class made this dictionary a moment ago and nobody else holds it yet.
        const auto state = static_cast<CFMutableDictionaryRef>(const_cast<void*>(*outData));
        const auto names = ausdk::Owned<CFArrayRef>::from_create(copyPresetNames());
        const auto name = [&names](int set) { return static_cast<CFStringRef>(CFArrayGetValueAtIndex(*names, set)); };

        CFMutableDictionaryRef pads = CFDictionaryCreateMutable(nullptr, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        setInt(pads, CFSTR("mode"), fanfrnoch_get_mode(engine_));
        setInt(pads, CFSTR("keyboardProgram"), fanfrnoch_get_program(engine_, FANFRNOCH_KEYBOARD_SET));
        setInt(pads, CFSTR("selectedPad"), static_cast<SInt32>(selectedPad_.load(std::memory_order_relaxed)));
        CFDictionarySetValue(pads, CFSTR("keyboardPreset"), name(FANFRNOCH_KEYBOARD_SET));
        CFMutableArrayRef list = CFArrayCreateMutable(nullptr, FANFRNOCH_NUM_PADS, &kCFTypeArrayCallBacks);
        for (int pad = 0; pad < FANFRNOCH_NUM_PADS; ++pad)
        {
            CFDictionaryRef saved = copyPad(engine_, pad, name(pad + 1));
            CFArrayAppendValue(list, saved);
            CFRelease(saved);
        }
        CFDictionarySetValue(pads, CFSTR("pads"), list);
        CFRelease(list);
        CFDictionarySetValue(state, padsKey(), pads);
        CFRelease(pads);

        // The controllers only: a learn in progress is not saved.
        std::vector<SInt32> controllers(static_cast<size_t>(knobs_));
        for (int i = 0; i < knobs_; ++i) controllers[static_cast<size_t>(i)] = fanfrnoch_get_controller(engine_, i);
        CFDataRef data = CFDataCreate(nullptr, reinterpret_cast<const UInt8*>(controllers.data()),
                                      static_cast<CFIndex>(controllers.size() * sizeof(SInt32)));
        CFDictionarySetValue(state, controllersKey(), data);
        CFRelease(data);
        return noErr;
    }

    // State without the pads leaves them alone (the default kit); a shorter list of pads leaves
    // the rest alone. Whatever is missing or of the wrong type is left as it is, but for the
    // presets in use: a set the state brings back holds the state's values, so it keeps the name
    // the state gives it, or none. The keyboard set's values came with the base class's
    // parameters: of its program only the number is put back, so that a reset to the program's
    // value finds the right program. State without controllers leaves them alone.
    OSStatus RestoreState(CFPropertyListRef plist) override
    {
        const OSStatus status = Base::RestoreState(plist);
        if (status != noErr || !plist || CFGetTypeID(plist) != CFDictionaryGetTypeID()) return status;
        const auto state = static_cast<CFDictionaryRef>(plist);
        restoreControllers(state);

        const auto before = ausdk::Owned<CFArrayRef>::from_create(copyPresetNames());
        CFMutableArrayRef names = CFArrayCreateMutableCopy(nullptr, FANFRNOCH_NUM_SETS, *before);
        const void* stored = CFDictionaryGetValue(state, padsKey());
        const auto pads = stored && CFGetTypeID(stored) == CFDictionaryGetTypeID() ? static_cast<CFDictionaryRef>(stored) : nullptr;
        CFStringRef keyboardName = pads ? copyName(pads, CFSTR("keyboardPreset")) : copyNoName();
        CFArraySetValueAtIndex(names, FANFRNOCH_KEYBOARD_SET, keyboardName);
        CFRelease(keyboardName);
        if (pads) restorePads(pads, names);
        replacePresetNames(CFArrayCreateCopy(nullptr, names));
        CFRelease(names);
        return status;
    }

    // ----- parameters -----------------------------------------------------------------------
    OSStatus GetParameterInfo(AudioUnitScope scope, AudioUnitParameterID id, AudioUnitParameterInfo& out) override
    {
        if (scope != kAudioUnitScope_Global) return kAudioUnitErr_InvalidScope;
        if (id >= static_cast<AudioUnitParameterID>(fanfrnoch_num_params())) return kAudioUnitErr_InvalidParameter;
        FanfrnochParamInfo info{};
        fanfrnoch_param_info(static_cast<int>(id), &info);

        out.flags = kAudioUnitParameterFlag_IsReadable | kAudioUnitParameterFlag_IsWritable;
        FillInParameterName(out, CFStringCreateWithCString(nullptr, info.name, kCFStringEncodingUTF8), true);
        if (info.section >= 0) HasClump(out, clumpOf(info));     // the LFO and VEL amounts are in none
        out.unit = unitOf(info);
        out.minValue = info.minValue;
        out.maxValue = info.maxValue;
        out.defaultValue = info.defaultValue;
        if (info.logarithmic) out.flags |= kAudioUnitParameterFlag_DisplayLogarithmic;
        return noErr;
    }

    OSStatus GetParameterValueStrings(AudioUnitScope scope, AudioUnitParameterID id, CFArrayRef* outStrings) override
    {
        if (scope != kAudioUnitScope_Global) return kAudioUnitErr_InvalidScope;
        if (id >= static_cast<AudioUnitParameterID>(fanfrnoch_num_params())) return kAudioUnitErr_InvalidParameter;
        FanfrnochParamInfo info{};
        fanfrnoch_param_info(static_cast<int>(id), &info);
        if (info.numChoices <= 0) return kAudioUnitErr_InvalidProperty;
        if (!outStrings) return noErr;                       // the host only asked whether there are any
        CFMutableArrayRef names = CFArrayCreateMutable(nullptr, info.numChoices, &kCFTypeArrayCallBacks);
        for (int c = 0; c < info.numChoices; ++c)
        {
            CFStringRef name = CFStringCreateWithCString(nullptr, fanfrnoch_param_choice(static_cast<int>(id), c), kCFStringEncodingUTF8);
            CFArrayAppendValue(names, name);
            CFRelease(name);
        }
        *outStrings = names;
        return noErr;
    }

    OSStatus CopyClumpName(AudioUnitScope, UInt32 clump, UInt32, CFStringRef* outName) override
    {
        if (clump < 1 || clump > static_cast<UInt32>(fanfrnoch_num_sections())) return kAudioUnitErr_InvalidPropertyValue;
        *outName = CFStringCreateWithCString(nullptr, fanfrnoch_section_name(static_cast<int>(clump) - 1), kCFStringEncodingUTF8);
        return noErr;
    }

    // ----- factory presets (the engine's built-in programs) ---------------------------------
    OSStatus GetPresets(CFArrayRef* outData) const override
    {
        if (!outData) return noErr;
        const std::vector<AUPreset>& presets = factoryPresets();
        CFMutableArrayRef array = CFArrayCreateMutable(nullptr, static_cast<CFIndex>(presets.size()), nullptr);
        for (const AUPreset& p : presets) CFArrayAppendValue(array, &p);
        *outData = array;
        return noErr;
    }

    // A program loads into the keyboard set, as the unit's parameters are; the pads keep theirs.
    // Only the render thread writes the keyboard set's values (from applied_): it sees the
    // parameters change as it sees any host change and sets the values the program just put in.
    // Here the engine only records which program the set now holds. The host's program ends the
    // keyboard's preset in use, open window or not, so a project saved now does not name it.
    OSStatus NewFactoryPresetSet(const AUPreset& preset) override
    {
        const SInt32 number = preset.presetNumber;
        if (number < 0 || number >= fanfrnoch_num_programs()) return kAudioUnitErr_InvalidPropertyValue;
        fanfrnoch_set_program_index(engine_, FANFRNOCH_KEYBOARD_SET, number);
        forgetKeyboardPreset();
        for (int i = 0; i < fanfrnoch_num_params(); ++i)
        {
            if (!fanfrnoch_program_sets(i)) continue;           // Octave stays where the player put it
            Globals()->SetParameter(static_cast<AudioUnitParameterID>(i), fanfrnoch_program_value(number, i));
        }
        SetAFactoryPresetAsCurrent(factoryPresets()[static_cast<size_t>(number)]);
        return noErr;
    }

    // ----- MIDI -----------------------------------------------------------------------------
    // Everything goes to the engine as raw MIDI. A host may call this on the render thread or on
    // another one, so the event is posted, which is safe and lock-free on either.
    OSStatus HandleMIDIEvent(UInt8 status, UInt8 channel, UInt8 data1, UInt8 data2, UInt32 offsetFrames) AUSDK_RTSAFE override
    {
        fanfrnoch_post_midi(engine_, status | channel, data1, data2, static_cast<int>(offsetFrames));
        return noErr;
    }

    // ----- render ---------------------------------------------------------------------------
    OSStatus Render(AudioUnitRenderActionFlags&, const AudioTimeStamp&, UInt32 frames) AUSDK_RTSAFE override
    {
        // Parameters the host or its automation changed since the last block.
        const int count = static_cast<int>(applied_.size());
        for (int i = 0; i < count; ++i)
        {
            const float value = Globals()->GetParameter(static_cast<AudioUnitParameterID>(i));
            if (value != applied_[static_cast<size_t>(i)])
            {
                applied_[static_cast<size_t>(i)] = value;
                fanfrnoch_set_plain(engine_, FANFRNOCH_KEYBOARD_SET, i, value);
                heard_[static_cast<size_t>(i)] = fanfrnoch_get_plain(engine_, FANFRNOCH_KEYBOARD_SET, i);
            }
        }

        const OSStatus status = process(frames);

        // A controller moved a knob inside the engine: the unit's own parameters follow, since
        // they are what a host and the window read and what is saved, and the host is told, as
        // it is of a change it makes itself with AUParameterSet. A knob the engine holds as the
        // host left it is not touched: the engine keeps knobs as 0...1 positions, so its plain
        // value can be a few ulps off the host's, and the host's stays.
        const unsigned changes = fanfrnoch_changes(engine_);
        if (changes != seenChanges_)
        {
            seenChanges_ = changes;
            for (int i = 0; i < count; ++i)
            {
                const float value = fanfrnoch_get_plain(engine_, FANFRNOCH_KEYBOARD_SET, i);
                if (value == heard_[static_cast<size_t>(i)]) continue;
                heard_[static_cast<size_t>(i)] = value;
                applied_[static_cast<size_t>(i)] = value;           // or the next block would hand the host's value back
                Globals()->SetParameterRT(static_cast<AudioUnitParameterID>(i), value, true);
                const AudioUnitParameter parameter{ GetComponentInstance(), static_cast<AudioUnitParameterID>(i), kAudioUnitScope_Global, 0 };
                AUParameterListenerNotify(nullptr, nullptr, &parameter);
            }
        }
        return status;
    }

private:
    // The block, into the output's buffers.
    OSStatus process(UInt32 frames) AUSDK_RTSAFE
    {
        AudioBufferList& buffers = Output(0).GetBufferList();
        float* left = static_cast<float*>(buffers.mBuffers[0].mData);
        if (buffers.mNumberBuffers > 1)
        {
            fanfrnoch_process(engine_, left, static_cast<float*>(buffers.mBuffers[1].mData), static_cast<int>(frames));
            return noErr;
        }

        // Mono: (L + R) / 2, so that a voice panned to one side is still heard.
        const UInt32 room = static_cast<UInt32>(scratchLeft_.size());
        if (room == 0) return kAudioUnitErr_Uninitialized;
        for (UInt32 done = 0; done < frames;)
        {
            const UInt32 n = std::min(room, frames - done);
            fanfrnoch_process(engine_, scratchLeft_.data(), scratchRight_.data(), static_cast<int>(n));
            for (UInt32 i = 0; i < n; ++i) left[done + i] = 0.5f * (scratchLeft_[i] + scratchRight_[i]);
            done += n;
        }
        return noErr;
    }

    // First the knobs that are to have none, then the others: giving a controller takes it from
    // whoever has it. A list from a version with fewer knobs covers the first of them; a value
    // that is no controller a knob can have means none.
    void restoreControllers(CFDictionaryRef state)
    {
        const void* stored = CFDictionaryGetValue(state, controllersKey());
        if (!stored || CFGetTypeID(stored) != CFDataGetTypeID()) return;
        const auto data = static_cast<CFDataRef>(stored);
        const int count = std::min(knobs_, static_cast<int>(CFDataGetLength(data) / static_cast<CFIndex>(sizeof(SInt32))));
        if (count <= 0) return;
        std::vector<SInt32> controllers(static_cast<size_t>(count));
        std::memcpy(controllers.data(), CFDataGetBytePtr(data), controllers.size() * sizeof(SInt32));   // CFData need not be aligned
        for (SInt32& cc : controllers)
            if (cc < 0 || cc > 127 || fanfrnoch_controller_reserved(cc)) cc = -1;
        for (int i = 0; i < count; ++i) if (controllers[static_cast<size_t>(i)] < 0) fanfrnoch_set_controller(engine_, i, -1);
        for (int i = 0; i < count; ++i) if (controllers[static_cast<size_t>(i)] >= 0) fanfrnoch_set_controller(engine_, i, controllers[static_cast<size_t>(i)]);
    }

    // The presets in use, retained (+1), and a new list of them (taken over, made with a Create
    // call). The window sets them on the main thread, but a host saves and restores the unit's
    // state on a thread of its choosing, and the SDK does not serialise those calls: whoever
    // reads them takes a reference of its own under the lock, and the list it reads is never
    // changed, only replaced. The list replaced is released outside the lock. Never the render
    // thread's business.
    CFArrayRef copyPresetNames()
    {
        std::lock_guard<std::mutex> lock(presetNamesLock_);
        return static_cast<CFArrayRef>(CFRetain(*presetNames_));
    }

    void replacePresetNames(CFArrayRef names)
    {
        auto replaced = ausdk::Owned<CFArrayRef>::from_create(names);
        std::lock_guard<std::mutex> lock(presetNamesLock_);
        std::swap(presetNames_, replaced);
    }

    // The keyboard set's name taken out of the presets in use, the pads' left as they are. Read
    // and replaced under one hold of the lock, so a list the window sets meanwhile is not lost;
    // the list replaced is released outside it.
    void forgetKeyboardPreset()
    {
        ausdk::Owned<CFArrayRef> replaced;
        std::lock_guard<std::mutex> lock(presetNamesLock_);
        CFMutableArrayRef names = CFArrayCreateMutableCopy(nullptr, FANFRNOCH_NUM_SETS, *presetNames_);
        CFArraySetValueAtIndex(names, FANFRNOCH_KEYBOARD_SET, CFSTR(""));
        replaced = ausdk::Owned<CFArrayRef>::from_create(CFArrayCreateCopy(nullptr, names));
        CFRelease(names);
        std::swap(presetNames_, replaced);
    }

    // The pads, the mode and the window's pad from "fanfrnoch-pads"; each pad the state has brings
    // its preset's name into `names`.
    void restorePads(CFDictionaryRef pads, CFMutableArrayRef names)
    {
        int number = 0;
        if (getInt(pads, CFSTR("mode"), number)) fanfrnoch_set_mode(engine_, number);
        if (getInt(pads, CFSTR("keyboardProgram"), number)) fanfrnoch_set_program_index(engine_, FANFRNOCH_KEYBOARD_SET, number);
        if (getInt(pads, CFSTR("selectedPad"), number) && number >= 0 && number < FANFRNOCH_NUM_PADS)
            selectedPad_.store(static_cast<UInt32>(number), std::memory_order_relaxed);
        const void* list = CFDictionaryGetValue(pads, CFSTR("pads"));
        if (!list || CFGetTypeID(list) != CFArrayGetTypeID()) return;
        const auto array = static_cast<CFArrayRef>(list);
        const int count = std::min(static_cast<int>(CFArrayGetCount(array)), static_cast<int>(FANFRNOCH_NUM_PADS));
        for (int pad = 0; pad < count; ++pad)
        {
            const void* saved = CFArrayGetValueAtIndex(array, pad);
            if (!saved || CFGetTypeID(saved) != CFDictionaryGetTypeID()) continue;
            const auto dict = static_cast<CFDictionaryRef>(saved);
            restorePad(engine_, pad, dict);
            CFStringRef name = copyName(dict, CFSTR("preset"));
            CFArraySetValueAtIndex(names, pad + 1, name);
            CFRelease(name);
        }
    }

    FanfrnochEngine* engine_;
    const int knobs_;                     // the parameters that can have a controller
    std::vector<float> applied_;          // the plain value last handed to the engine, per parameter
    std::vector<float> heard_;            // the engine's plain value as the unit's parameter last matched it
    unsigned seenChanges_ = 0;            // the engine's count of what MIDI changed, as of the last block
    std::atomic<UInt32> selectedPad_{ 0 }; // the pad the window shows
    std::mutex presetNamesLock_;
    ausdk::Owned<CFArrayRef> presetNames_; // the preset each set came from, "" for none; under presetNamesLock_
    std::vector<float> scratchLeft_;      // stereo for a mono output, made in Initialize
    std::vector<float> scratchRight_;
    std::atomic<Float64> latency_{ 0.0 }; // seconds, as of the last Initialize (before it: at kStartRate)
    const Float64 tail_;                  // seconds
};

AUSDK_COMPONENT_ENTRY(ausdk::AUMusicDeviceFactory, FanfrnochAU)
