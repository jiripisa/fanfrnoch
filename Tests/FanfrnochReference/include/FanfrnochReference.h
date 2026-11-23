// The listening prototype (.planning/research/spike/fanfrnoch_spike.cpp) as a test reference.
// It runs at a fixed 96 kHz. Units are the prototype's own: fractions, not percent.
#ifndef FANFRNOCH_REFERENCE_H
#define FANFRNOCH_REFERENCE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct FanfrnochRefParams {
    float ring, edge, offset, bodyDb, buzz, clang, velsens; int stroke;
    float damp, vary, vowel, sweep, sweeptime; int curve; float reso, throatDb, throattune,
    open, close, breath, puff, pufftime, air; int levelOnlyVelocity;
} FanfrnochRefParams;

typedef struct FanfrnochRefEvent { double time; int note; float velocity; int params; int chokeOnly; } FanfrnochRefEvent;

void fanfrnoch_ref_default_params(FanfrnochRefParams* out);

// Renders `frames` mono samples at 96 kHz: events sorted by time, `params` indexes `paramSets`.
void fanfrnoch_ref_render(const FanfrnochRefEvent* events, int numEvents,
                       const FanfrnochRefParams* paramSets, int numParamSets, float* out, int frames);

#ifdef __cplusplus
}
#endif

#endif
