# Phase 02 — Verification (2026-11-23)

The engine is the friction drum now, but the panel is still Brumle's layout with Fanfrnoch's
sections, and its art is still the jaw harp's (phases 03 and 04). Everything below was checked
through the C interface, the `Synth` wrapper, the Audio Unit in the test process, `auval` and
rendered files. The author has not listened to the engine's renders yet.

| Check | Result |
|---|---|
| `swift build` | complete |
| `swift test` | 284 tests in 33 suites pass (16.9 s) |
| `swift test -c release` | 284 tests in 33 suites pass (3.5 s); the 54 regression references hold in both builds (debug and release render the same samples) |
| `swift test --sanitize=thread` | 284 tests pass (121.9 s), no ThreadSanitizer report |
| `./build.sh release` | succeeds: `build/release/Fanfrnoch.app` with `Fanfrnoch.component` |
| `auval -v aumu Fanf JPis` | `AU VALIDATION SUCCEEDED`: 103 global parameters, factory presets (default 0, Fanfrnoch); the component was copied to `~/Library/Audio/Plug-Ins/Components/` for the run and removed afterwards |
| `build/release/Fanfrnoch.app`, started by path | runs; quit at once (the window was not looked at) |
| Prototype equivalence (50 comparisons, engine vs `Tests/FanfrnochReference`) | at 96 kHz 41 spike renders −144.6 … −149.0 dB; at 48 kHz (voices at 96 kHz, both through the engine's decimator) 7 renders −133.7 … −133.8 dB; the default kit's groups −122.0 dB; Drum Many −144.8 dB. Worst −122.0 dB |
| Output level | `kLevel` 0.32: the default stroke (B2, velocity 127) peaks at 0.50, −6.1 dBFS (median of 40 strokes at 48 kHz; Vary and the noise spread them from 0.37 to 0.74); the limiter is transparent up to 0.6 |
| Aliasing at 44.1 kHz, Stick 0.95 (no darkening), 860 Hz | the warped cosine's alias products: worst single product −50.9 dB re the fundamental without oversampling (Fourier series of the waveform; −57.2 dB at 48 kHz), −76.6 dB with the 2× stage. Measured (`EngineTests.aliasing`, power between the harmonics below 20 kHz re all): −48.2 dB through the reference at the host rate, −68.9 dB through the engine. **The 2× stage stays** |
| Latency | 29 host frames at 44.1 and 48 kHz, 0 from 88.2 kHz (Brumle's decimator, unchanged) |
| CPU (`EngineTests.cpuPerVoice`, 16 voices of the longest Fanfrnoch with both body resonances on, 2 s at 48 kHz) | release build: 1.40–1.45 % of one core per voice (16 voices ≈ 23 %); debug build 5.2 % |
| Voices | 40 slots, at most 16 sounding; floods of 16 pads (each its own drum), of 24 keys with Drum Many, and of pads over sounding keys reach 16 and never exceed it |

## The reference and the approved renders

`Tests/FanfrnochReference` is the spike's `Params`, `Bandpass`, `SlowNoise`, `Voice` and `render`,
amended where the engine must differ (each marked in the file): the rate is a variable, and the
DC blocker's coefficient, the Scrape's and the Creak's noise and the Creak's impulses are scaled to
sound at every rate as at 48 kHz (each scale is 1 at 48 kHz); an event carries its parameter set
(the pads of one group); a key's release is an event that sets the stroke's `hold`; a stroke on a
drum whose voice has retired starts a fresh voice, seeded 1, 2, 3 … as the engine seeds; `exp2` for
`pow(2, x)`; a stable sort; the engine's decimator below 88.2 kHz.

Checked outside the suite (`scratchpad/refcheck`): at 48 kHz this copy writes **42 of the spike's 45
mono renders byte for byte** (the spike built with `-O2 -ffp-contract=off`). The three others differ
as intended: 02d (the hold is found at the note-off, at most a sample from the spike's), P01 (its
voice retires between strokes, and a fresh voice draws other noise), P09 (the spike seeded its
three drums 1, 5, 6; the engine seeds 1, 2, 3). The approved files in
`.planning/research/spike/renders/` are the spike's default `clang++ -O2` build, whose fused
multiply-adds round differently: 21 of its 46 renders differ from the no-FMA build in last bits
(in some, an event lands a sample later).

The engine's own 48 kHz versions of every spike render (`ListeningRenders`, Volume −12 dB, in the
session's scratchpad `engine-renders/`, not in the repository) against the approved files, through
the research's analysis tool (`ana` + `post.py`, per-stroke medians):

| Measure | Engine vs approved | The spike against itself with other seeds |
|---|---|---|
| f0 | equal in every render (P04 alternates two notes: 72 vs 71 Hz median) | equal |
| HNR | within 0.7 dB (worst 14_range_62Hz_track100: 8.3 vs 9.0) | within 0.5 dB |
| H2…H8 re H1 | within 3.1 dB (12a), most within 1.5 dB | within 2.7 dB (09c) |
| attack, release (medians) | up to 55 ms / 267 dB/s apart on overlapping strokes | up to 26 ms / 365 dB/s |

The harmonic levels and envelope times of the noisy renders differ by about as much as the spike
differs from itself with another seed: the rub noise moves the measured peaks. Without the noise
(Vary, Wobble, Shimmer, Rub, Scrape at 0, `scratchpad/tonecheck`) the spike's 48 kHz tone and the
engine's path (96 kHz decimated) measure H1…H11 identical to 0.1 dB at B2 (Stick 0.88 and 0.95),
G3 (0.80) and 860 Hz (0.95), and the same envelope (attack 47 / 46 ms in 5 ms frames, release
204 / 203 dB/s, f0 123 Hz).

## Decisions [builder]

- **Oversampling kept**, from the measurement above (spec §5).
- **The random generator kept** (`std::mt19937`, `uniform_real_distribution<double>`, the spike's
  draws in the spike's order): the engine is the approved prototype to −149 dB. It costs about
  1.4 % of a core per voice; a cheaper generator is the first saving if a host needs it.
- **Control rate:** only what the spike computes every sample from fixed knobs (the envelope's
  coefficients, the levels, the body's and the rub's filters, the pitch offsets) is worked out at
  the 16-sample tick, which gives the same numbers; nothing that moves within a tick was moved.
- **Rate scaling anchored at 48 kHz** (above): the voices run at 88.2 or 96 kHz and must sound as
  the approved 48 kHz renders.
- **`exp2` for `pow(2, x)`** in the engine and the reference: an optimised build rewrites the one
  into the other, and they differ in a last bit now and then, so debug and release rendered
  different samples (found by `swift test -c release`).
- **The per-voice DC blocker** is the spike's; Brumle's bus DC blocker is gone (it would add a
  second high-pass).
- **Knob ranges:** logarithmic Attack, Release, Scoop Time, Creak Rate, Creak Ring, Pot, Pot Q,
  Skin, Skin Q and the LFO rates; the rest linear. Pot Level (−40…+18 dB), Skin Level (−40…+6 dB)
  and Rub (−40…0 dB) are Off at the bottom of their travel, the spike's −200 dB.
- **Identifier `velpitch`** for Vel>Pitch: the design's `veltune` is also the VEL amount of Tune
  (`vel` + `tune`). A test now checks that no two parameters share an identifier.
- **LFO "Pitch"** is LFO>Tune (Tune is ±100 cents: an amount of 50 % moves the pitch ±100 cents);
  Tune and the pitch bend are added to the pitch in semitones at every tick.
- **Wheels** move knob positions, as Brumle's: the mod wheel adds half of Rub's travel (+20 dB,
  capped at 0 dB), aftertouch 0.07/0.45 of Stick's (capped at the knob's top, 0.95); pitch bend
  bends by Bend Up / Bend Down. Keyboard voices only.
- **All Sound Off / All Notes Off** fade every voice out in 10 ms (Brumle used Damp, which is now a
  percentage of the release).
- **Voices and drums:** a new voice is seeded 1, 2, 3 … from the reset; the strokes are counted per
  drum, so the hands alternate on across a voice's retirement; a stroke on a drum whose voice is
  fading out (stolen) starts a new voice. The note-off of the stroke's own key gives the hold:
  with Drum One the hand belongs to the last stroke.
- **Program levels:** the spike normalised every render, so it set no levels. The four programs
  whose full-velocity stroke peaks more than 3 dB over the default's are turned down by Volume:
  Brummtopf −5.5, Zambomba Grave −8, Furruco −3.5, Buhai −9 dB. The quieter ones (Cuíca Whoop
  5 dB and Flick 7 dB under the default) keep their softness.
- **Default kit:** pads 10 and 11 are the Zambomba with Jump 0 % and 100 %; the notes are the
  design's.
- **Standard controllers:** 73 Attack, 72 Release, 74 Stick, 71 Pot Q, 2 Rub, 7 Volume, 10 Pan, the
  others 14–31, 85–90 and 102–115 in table order.
- **Audio Unit tail:** the top of Length, three tops of Release and 0.1 s: 11.1 s.
- **The panel's plan** (`SectionLayout`) puts the seven sections in 13 columns, about Brumle's 12;
  phase 04 lays them out properly.

## Deviations from the spec and the prototype

- Render 13b (the spike's polyphonic restarts) is not one of the engine's sounds: the design chose
  one drum per head (§2). Its sound is near pads with Group Off played in turn; it is not in the
  equivalence tests.
- The identifier `velpitch` (above).
- The reference's amendments (above); none of them changes the approved sound at 48 kHz but the
  three renders named.
- `EngineTests`: the voice-pool flood on the pads plays program Fanfrnoch on C2 with no Scrape, so
  that its biggest-step bound still detects a cut voice: sixteen strokes starting together, each
  with its Scrape's noise or a high note's fast slip, step by up to 0.55 without any cut.

## Not verified

- **By ear:** the author has not heard the engine's renders. They are in the session's scratchpad
  (`engine-renders/`, 54 files: the 45 spike renders and F01–F08 for the wheels, LFO, VEL, pan
  and the default kit), not in the repository; `FANFRNOCH_LISTEN_DIR=<dir> swift test --filter
  ListeningRenders` writes them again.
- **Real time:** no host and no audio device; the audio thread's rules are checked by reading and
  by the TSan test.
- **The panel:** it compiles and the app starts; nobody looked at it. The art still shows the
  khomus (`Artwork.khomus`, `KhomusView`): phase 03.
- The wheels are unsmoothed, as in Brumle.
- The CPU figure is one machine, offline, in a test.
