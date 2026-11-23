// FanfrnochDSP.h - C interface to the Fanfrnoch sound engine.
//
// One engine = a friction drum and its relatives: sixteen voices that the player's hands (the
// keyboard) or the sixteen pads of a kit strike. A voice belongs to a drum; a stroke on a drum
// that sounds continues its voice. The Audio Unit (C++) and the standalone app (Swift, through
// FanfrnochCore) both drive it through these functions.
//
// Threads:
//   * fanfrnoch_process() and fanfrnoch_midi() belong to the audio thread.
//   * fanfrnoch_post_midi(), the parameter setters/getters, fanfrnoch_set_program(), the mode and
//     pad calls and fanfrnoch_request_reset() may be called from any thread while audio runs,
//     the audio thread included: none of them locks or allocates.
//   * fanfrnoch_prepare() and fanfrnoch_reset() must not run concurrently with fanfrnoch_process().
//
// Parameter values come in two forms: "plain" (the real value: s, Hz, dB, %, an index) and
// "normalised" (0..1, what a knob position is). The engine stores normalised values.
//
// Sets: the sound is a set of knobs (the parameters below). The keyboard has one set; each of
// the 16 pads has a set of its own, so that every pad can sound different. A set is addressed by
// an index: FANFRNOCH_KEYBOARD_SET (0), or 1...16 for a pad.

#ifndef FANFRNOCH_DSP_H
#define FANFRNOCH_DSP_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct FanfrnochEngine FanfrnochEngine;

enum { FANFRNOCH_KIND_FLOAT = 0, FANFRNOCH_KIND_INT = 1, FANFRNOCH_KIND_CHOICE = 2 };
enum { FANFRNOCH_MODE_KEYBOARD = 0, FANFRNOCH_MODE_PADS = 1 };
enum { FANFRNOCH_KEYBOARD_SET = 0, FANFRNOCH_NUM_PADS = 16, FANFRNOCH_NUM_SETS = 17,
       FANFRNOCH_FIRST_PAD_NOTE = 36, FANFRNOCH_NUM_GROUPS = 16, FANFRNOCH_MAX_VOICES = 16 };

typedef struct FanfrnochParamInfo
{
    const char* identifier;   // stable name used in saved state; never changes
    const char* name;         // shown to the user
    const char* unit;         // "s", "Hz", "ms", "dB", "%", "st", "ct" or ""
    int   kind;               // FANFRNOCH_KIND_*
    float minValue, maxValue, defaultValue;   // plain values
    int   logarithmic;        // 1 = the knob travels logarithmically (times, frequencies)
    int   numChoices;         // > 0 only for FANFRNOCH_KIND_CHOICE
    int   section;            // the section it is shown in (see fanfrnoch_num_sections), -1 if none
} FanfrnochParamInfo;

// ----- parameter, section and program tables (the same for every engine) --------------------
int         fanfrnoch_num_params(void);
void        fanfrnoch_param_info(int index, FanfrnochParamInfo* out);
const char* fanfrnoch_param_choice(int index, int choice);
float       fanfrnoch_param_to_plain(int index, float normalised);
float       fanfrnoch_param_to_normalised(int index, float plain);
// Text for a plain value, without the unit ("4.00", "-24.0", "Alternate", "+1"). Returns buffer.
const char* fanfrnoch_param_display(int index, float plain, char* buffer, int bufferSize);

// The sections the knobs are shown in ("Stroke", "Hands", "Pitch", "Friction", "Body", "Noise",
// "Master") and the
// knobs of each in the order they are shown: the app's panels and the Audio Unit's parameter
// groups. The amounts below are in no section.
int         fanfrnoch_num_sections(void);
const char* fanfrnoch_section_name(int s);
int         fanfrnoch_section_size(int s);
int         fanfrnoch_section_param(int s, int pos);   // a parameter index, -1 if none

// The modulation slots. Each of the two LFOs has an amount on every knob it can move, and the
// hit's velocity has one on every knob it can move: parameters of their own, shown in no
// section. The call gives the amount's index, or -1 for a knob that cannot be moved so.
int         fanfrnoch_num_lfos(void);
int         fanfrnoch_lfo_amount(int lfo, int param);
int         fanfrnoch_vel_amount(int param);

int         fanfrnoch_num_programs(void);
const char* fanfrnoch_program_name(int p);
float       fanfrnoch_program_value(int p, int param);   // plain
int         fanfrnoch_program_sets(int param);           // 0 for "octave", which programs leave alone

// ----- one engine ---------------------------------------------------------------------------
FanfrnochEngine* fanfrnoch_create(void);
void          fanfrnoch_destroy(FanfrnochEngine*);
// Sets the host sample rate and then resets the engine as fanfrnoch_reset() does. A rate that is not
// positive and finite is ignored, and nothing is reset.
void          fanfrnoch_prepare(FanfrnochEngine*, double sampleRate);
// Silences every voice, puts the wheels at rest, forgets the last note and starts every drum's
// alternation again from its first hand. The knob sets, the pads (notes, groups) and the mode
// stay as they are.
void          fanfrnoch_reset(FanfrnochEngine*);
// The same reset, done by the audio thread at the start of its next fanfrnoch_process() call.
void          fanfrnoch_request_reset(FanfrnochEngine*);
// Host frames the output lags the MIDI: the decimator's delay below 88.2 kHz, where the voices run
// at twice the rate, and 0 from 88.2 kHz up.
int           fanfrnoch_latency(const FanfrnochEngine*);

float fanfrnoch_get_plain(const FanfrnochEngine*, int set, int index);
float fanfrnoch_get_normalised(const FanfrnochEngine*, int set, int index);
void  fanfrnoch_set_plain(FanfrnochEngine*, int set, int index, float plain);
void  fanfrnoch_set_normalised(FanfrnochEngine*, int set, int index, float n);

// Loads a built-in program into a set: every parameter but "octave" is overwritten. The octave
// belongs to the player's hands, not to the sound.
void  fanfrnoch_set_program(FanfrnochEngine*, int set, int program);
int   fanfrnoch_get_program(const FanfrnochEngine*, int set);
// Records which program a set last loaded without loading it: no knob changes. For restoring saved
// state whose knob values come from elsewhere. A bad set or program is ignored.
void  fanfrnoch_set_program_index(FanfrnochEngine*, int set, int program);

// The mode: the keyboard plays the keyboard set at the pitch of each key, as one drum (Drum One)
// or a drum per note (Drum Many); the pads play their own sets at the pitch of each pad, hit by
// notes 36-51 (other notes are ignored). A voice already sounding when the mode changes sounds
// on as it was.
void  fanfrnoch_set_mode(FanfrnochEngine*, int mode);
int   fanfrnoch_get_mode(const FanfrnochEngine*);

// Pads: each has a pitch (a MIDI note) and a group. The pads of one group are one drum: a hit
// continues the group's sounding voice with the new pad's set and pitch. A pad whose group is
// 0 (Off) is a drum of its own, which a re-hit continues. Like the pitch, the group belongs to
// the pad, not to its set. A pad's voice copies the pad's set at the hit and does not follow
// later changes to it, nor the wheels.
int   fanfrnoch_pad_note(const FanfrnochEngine*, int pad);
void  fanfrnoch_set_pad_note(FanfrnochEngine*, int pad, int note);
int   fanfrnoch_pad_group(const FanfrnochEngine*, int pad);
void  fanfrnoch_set_pad_group(FanfrnochEngine*, int pad, int group);   // 0 = Off
// How many times a pad has been hit since the engine was created: the panel flashes a pad when it
// changes. Counted on the audio thread; a reset leaves it alone. 0 for a bad pad.
int   fanfrnoch_pad_hits(const FanfrnochEngine*, int pad);
int   fanfrnoch_last_note(const FanfrnochEngine*);          // last keyboard-mode note-on since the last reset, -1 if none
// Copies the keyboard set (and its program) and the pitch of the last note (36 if none) to a
// pad; its group is kept. The copy goes value by value with relaxed atomics, not as a whole: a pad
// hit landing mid-copy freezes a mix of old and new values for that one hit.
void  fanfrnoch_send_to_pad(FanfrnochEngine*, int pad);
// A kit built from the programs at various pitches, so that pad mode sounds at once: what the
// pads hold when the engine is created. Overwrites every pad's set, note and group, value by value
// with relaxed atomics like fanfrnoch_send_to_pad: a pad hit landing mid-load freezes a mix of old and
// new values for that one hit.
void  fanfrnoch_load_default_kit(FanfrnochEngine*);
int   fanfrnoch_sounding_voices(const FanfrnochEngine*);    // voices playing and not being faded out

// MIDI from any thread; played in the next fanfrnoch_process() call, sampleOffset frames into it
// (0 = at its start).
void  fanfrnoch_post_midi(FanfrnochEngine*, int status, int data1, int data2, int sampleOffset);
// MIDI from the audio thread with a sample offset into the next fanfrnoch_process() call.
void  fanfrnoch_midi(FanfrnochEngine*, int status, int data1, int data2, int sampleOffset);
// One fanfrnoch_process() call plays at most 256 events. Those from fanfrnoch_midi() take that room
// first, and any beyond it are dropped. Posted events beyond it stay queued and play in the next
// call, in the order posted, at their sample offset into that call. The queue holds 512 posted
// events; an event posted while it is full is dropped.

// MIDI controllers on the keyboard set's knobs. Every knob comes with a controller (a control
// change number) and can be given another; a control change on any channel then puts the knob
// of the keyboard set where its value says: 0 the bottom of its travel, 127 the top, and 64 the
// middle of a knob that has one (-100 ... 100 %). A choice takes the choice nearest to the value.
// The pads' sets are never moved, not in pad mode either. A controller serves one knob, and the
// amounts have none. The control change is applied at its sample offset, in the order of the
// block's MIDI. Controllers 1 (the mod wheel), 120, 121 and 123 keep their meanings. All of these
// may be called from any thread while audio runs.
int  fanfrnoch_standard_controller(int param);               // what a knob comes with; -1 for none
int  fanfrnoch_controller_reserved(int cc);                  // 1 for one MIDI or the engine keeps for itself
int  fanfrnoch_get_controller(const FanfrnochEngine*, int param);          // -1 for none
// -1 takes the knob's controller away. A reserved controller is not taken; one another knob has
// moves to this one.
void fanfrnoch_set_controller(FanfrnochEngine*, int param, int cc);
void fanfrnoch_reset_controllers(FanfrnochEngine*);             // every knob back to its standard controller
// Learn: the knob takes the next controller that moves, not a reserved one, and goes where it
// says. -1 (or a parameter that is not a knob) calls it off.
void fanfrnoch_learn(FanfrnochEngine*, int param);
int  fanfrnoch_learning(const FanfrnochEngine*);               // the knob that is learning, -1 for none
// Counts what MIDI changed without the caller: a knob moved by its controller, a controller
// learnt. A window compares it with what it saw last to know when to read the engine again: the
// count is raised after the change (release) and read with acquire, so a window that sees it rise
// reads the new values.
unsigned fanfrnoch_changes(const FanfrnochEngine*);

// Renders `frames` samples. `right` may be NULL: left then gets the left channel.
void  fanfrnoch_process(FanfrnochEngine*, float* left, float* right, int frames);

#ifdef __cplusplus
}
#endif

#endif // FANFRNOCH_DSP_H
