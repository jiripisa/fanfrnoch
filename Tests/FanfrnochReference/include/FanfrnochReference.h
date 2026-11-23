// The listening prototype (.planning/research/spike/fanfrnoch_spike.cpp) as a test reference.
// Units are the prototype's own: fractions, not percent, and its "off" levels are -200 dB.
#ifndef FANFRNOCH_REFERENCE_H
#define FANFRNOCH_REFERENCE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct FanfrnochRefParams {
    float attack, length, release, damp; int keyupStop;
    float alternate, alttune, vary, velsens;
    float scoop, scooptime, drift, drop, wobble, jump, jumpratio, veltune;
    float stick, stickvel, split, creak, creakrate, creakring;
    float pot, potq, potlevel, skin, skinq, skinlevel, track;
    float rub, scrape, shimmer;
} FanfrnochRefParams;

// A stroke on `drum` at `hz` with `params` (an index into the parameter sets), or with `noteOff`
// the moment the key of the drum's stroke is let go (the prototype's `hold`).
typedef struct FanfrnochRefEvent { double time; int drum; double hz; float velocity; int params; int noteOff; } FanfrnochRefEvent;

void fanfrnoch_ref_default_params(FanfrnochRefParams* out);

// Renders `frames` mono samples: the drums' voices at `voiceRate`, events in the order given
// (sorted by time). A drum sounds with one voice; a stroke on a silent drum starts a fresh one,
// whose generator is seeded 1, 2, 3, ... in the order the voices start. With `decimate` the
// voices' sum goes through the engine's half-band decimator and `frames` are at half the rate.
void fanfrnoch_ref_render(const FanfrnochRefEvent* events, int numEvents,
                          const FanfrnochRefParams* paramSets, int numParamSets, int numDrums,
                          double voiceRate, int decimate, float* out, int frames);

#ifdef __cplusplus
}
#endif

#endif
