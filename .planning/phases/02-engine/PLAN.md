# Phase 02 — the sound engine: Plan

**Goal:** `FanfrnochDSP` plays the approved friction-drum prototype
(`.planning/research/spike/fanfrnoch_spike.cpp`) in keyboard mode and pad mode, with Brumle's
whole architecture kept. Every Swift layer that depends on the parameter table (core, Audio Unit,
its window, the panel) follows, so that the package builds and every test passes.

**Spec:** `.planning/specs/2026-11-23-instrument-design.md` §5–§9. Pattern: Brumle's phase 02
(`../Brumle/.planning/phases/02-engine/`) and the engine this repo inherited from it.

**Branch:** `feature/02-engine` from `main`; merged back with `--no-ff` at the end of the phase
(not by this plan's builder). Never pushed without the author's explicit OK.

## Global constraints

- Audio thread: `fanfrnoch_process` and `fanfrnoch_midi` never allocate, lock, log or do I/O;
  `swift test --sanitize=thread` stays clean.
- Every engine `.cpp` starts with `#pragma clang fp contract(off)`: debug and release builds
  render the same samples.
- The voice keeps the prototype's order of operations and its random draws (`std::mt19937`,
  `uniform_real_distribution<double>`), so fixed knobs give the prototype's numbers.
- Control interval 16 internal samples, per voice, starting at its first sample.
- The parameter identifiers and their order (Task 1) are permanent from the first release.
- All LFO and VEL amounts default to 0.
- Conventional Commits with a scope, no AI attribution; `git status` before every commit.

## Tasks

1. **The parameter table** (`Params.h/.cpp`): the 45 knobs of spec §6 in its order, then the
   LFO amounts (11 targets × 2 LFOs), then the VEL amounts (36 targets): 103 parameters.
   Sections Stroke, Hands, Pitch, Friction, Body, Noise, Master. "Bottom = off" knobs show Off.
   One standard MIDI controller per knob. Twelve programs (spec §8) as overrides of the defaults,
   values from the spike's program functions. The default kit (spec §7).
   Test: `ParameterTableTests`.
2. **The reference** (`Tests/FanfrnochReference`): the spike's `Params`, `Bandpass`,
   `SlowNoise` and `Voice` copied, driven by a C interface: events with a drum, a pitch, a
   velocity, a parameter set and note-offs; drum seeds given by the caller; any voice rate, and
   optionally the engine's 2× decimation. Amendments, each identity at 48 kHz: the per-voice DC
   blocker, the Scrape noise and the Creak impulses are normalised to 48 kHz. Checked once
   outside the suite: at 48 kHz the copy writes the spike's renders byte for byte.
   Test: `ReferenceTests`.
3. **The voice and the drums** (`Voice.h`, `FanfrnochEngine.cpp`): the spike's voice ported
   line for line into Brumle's pool of 16 (40 slots, stealing with a 3 ms fade). A voice belongs
   to a drum: the keyboard (Drum One), a note (Drum Many), a group, or a pad with Group Off; a
   stroke on a sounding drum continues its voice (phase, envelope, filters); Alternate counts per
   drum. Key Up Stop ends the rubbing at note-off. The per-voice DC blocker replaces Brumle's bus
   blocker. Output: voices → sum → kLevel → [half-band] → limiter.
   Test: `PrototypeEquivalenceTests` (every spike score at 96 kHz and through the decimator at
   48 kHz, residual < −60 dB, aim −110 dB), `EngineTests`, `PadTests`.
4. **Modulation and wheels:** LFO and VEL amounts as Brumle; pitch bend by Bend Up / Bend Down,
   mod wheel adds Rub (+20 dB at the top), aftertouch adds Stick (+0.07); keyboard voices only.
   Test: `ModulationTests`.
5. **Rate and aliasing:** measure the alias products at 44.1 kHz, Stick 0.95, 860 Hz; keep the
   2× stage only if they exceed −60 dB re the fundamental. Default stroke at full velocity peaks
   about −6 dBFS before the limiter. CPU per voice from a timing test with 16 voices.
6. **Swift layers:** `FanfrnochCore` (Parameter, SectionLayout, Controllers, presets, kits,
   state), the Audio Unit (count, clumps, factory presets, tail), its window and the panel
   compile and show the new sections. Jaw-harp words leave `Sources/` and `Tests/`. Every test
   of behaviour that still exists is ported to the new parameters; jaw-harp behaviour tests are
   rewritten for the drum or removed.
7. **Regression references and listening renders:** `SoundRegressionTests` re-recorded for the
   spike's scores plus a fast alternating group, a scoop, a jump, creak, split and a held note
   with Key Up = Stop; `ListeningRenders` writes the engine's versions of the spike's renders,
   compared with the spike's by the analysis tool.
8. **Verification:** `swift build`, `swift test`, `swift test --sanitize=thread`,
   `./build.sh release`, `auval -v aumu Fanf JPis`; `VERIFICATION.md`.

## Acceptance

- Every spike score the engine can play matches the reference below −60 dB at 96 kHz and at
  48 kHz; the engine's 48 kHz renders measure like the approved renders (harmonics and HNR
  within 1 dB, same f0 and envelope timings).
- `swift test` green, TSan clean, release build and `auval` pass.
- CLAUDE.md names the new parameter-ID range.
