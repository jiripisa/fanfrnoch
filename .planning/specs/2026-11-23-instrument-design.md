# Fanfrnoch — design of the instrument (engine, two modes, architecture)

Status: written 2026-11-23 after the author's listening. The author approved every render of the
prototype ("zní to všechno strašně dobře") and asked for the whole product to be built and released
autonomously, Brumle-style, with Codex art. Approval of this document is therefore delegated: the
calls below are the builder's, open to the author's correction at any point.

Sources: the research report `.planning/research/reports/Friction drum acoustics and playing.md`
(with its notes) and the listening prototype `.planning/research/spike/fanfrnoch_spike.cpp`
(renders and guide: `.planning/research/spike/LISTENING.md`). Template project: `../Brumle`
(same author, same pipeline, released 1.0.0). Its `CLAUDE.md`, `development_workflow.md`, its
engine design (`../Brumle/.planning/specs/2026-11-15-engine-design.md`) and its code are the
pattern to follow.

Marking: **[author]** decided by the author; **[ear]** approved by the author's ear on the
prototype's renders; **[call]** a call made in design, open to correction; **[builder]** left
to whoever plans and builds.

## 1. Intent and the why

Fanfrnoch is a playable synthesized friction drum, named after the Czech horsehair friction
drum ("fanfrnoch", also famfrnoch or bručák): a clay jug or pot covered with bladder or leather,
two bundles of horsehair through the skin, pulled by wet hands. It is an AUv2 instrument for
Ableton Live, Logic and other hosts plus a standalone macOS app, built exactly like Brumle
**[author]**. It is used **primarily for rhythm**, like Brumle **[author]**. The sound was
chosen by ear on the prototype's renders **[ear]**, which also cover the relatives (Brummtopf,
zambomba, putipù, cuíca, furruco, creak, flick, buhai).

What makes it special: no product synthesizes a friction drum; every cuíca on the market is a
sample library. A synthesized stroke can glide, scoop, jump modes and be frozen onto a pad.

## 2. Goals, non-goals, anti-goals

**Goals**
- **Everything Brumle 1.0 has [author: "udělej to samé"].** Keyboard mode and pad mode
  (16 pads, notes 36–51, mute groups, Send to pad, pad editing), programs, user presets, kits,
  two LFOs and VEL amounts on the knobs, a MIDI controller per knob with learn, the app's MIDI
  input and audio output settings, the app installing the plug-in, Sparkle updates, the
  bilingual website and manual, signed and notarized DMG.
- **The prototype's sounds are the bar [ear].** Every render in `renders/` must be reachable
  with the plug-in's knobs and programs.
- **One drum is one head [call, report].** A stroke on a drum continues that drum's oscillator
  phase and level; strokes on one drum run into each other with a dip, not a click.
- Minimum macOS 26, Liquid Glass panel **[author, via Brumle]**.

**Non-goals**
- No internal sequencer; rhythm comes from notes or host patterns (as Brumle).
- No samples shipped. The reference recordings in `renders/references/` are for listening only.
- No AUv3 (it needs an app extension and so an Xcode project).
- No MPC plugin in this project's first release (Brumle's phase 09 is a later, separate step).

**Anti-goals**
- The plug-in sounds different from the approved renders.
- Pads that do not behave exactly like a key press of their frozen sound.
- Audio-thread allocation, locks, logging or I/O.
- Changing a parameter identifier or its order, or the AU's codes, after the first release.

## 3. Constraints

- SwiftPM plus shell scripts, never an Xcode project; Swift 6.2 tools, `.macOS(.v26)`.
- One C++ engine behind a C interface, shared by the app and the AU.
- AUv2 on Apple's vendored AudioUnitSDK, exactly as in Brumle.
- Audio thread rules as Brumle; 16-sample control interval; `swift test --sanitize=thread` clean.
- **Permanent identity from the first release [call]:** type `aumu`, subtype `Fanf`,
  manufacturer `JPis`; app bundle id `io.jp4.fanfrnoch`, component bundle id
  `io.jp4.fanfrnoch.audiounit`, factory function `FanfrnochAUFactory`, view class
  `FanfrnochAUViewFactory`, component name "Jiri Pisa: Fanfrnoch"; the parameter table's order.
- Files: presets `~/Library/Application Support/Fanfrnoch/Presets/*.fanfrnoch`, kits
  `…/Fanfrnoch/Kits/*.fanfrnochkit` **[call]**.
- Sparkle: the same EdDSA key as Brumle and Didgeridoo (one key in the login Keychain;
  `SUPublicEDKey` is identical in both apps) **[call]**. Feed at
  `https://jiripisa.github.io/fanfrnoch/appcast.xml`.
- Website: GitHub Pages from `main`/`docs`, EN and CS tag for tag; CHANGELOG line per
  user-visible change; manual describes every control.
- Pushes to GitHub only after the author's explicit OK (global rule).

## 4. Approaches considered

**How the product is built [author: A].**

| Approach | Trade-off | Outcome |
|---|---|---|
| A. Brumle as the template: copy, rename, replace the engine, programs and art | Inherits nine phases of fixes (audio thread, auval, project state, shared presets); risk of leftovers, guarded by a search for jaw-harp words | **Chosen by the author** |
| B. Fresh skeleton (`new-macos-app`) and port piece by piece | Cleaner, about twice the work, old bugs can return | Rejected |
| C. A library shared by Brumle and Fanfrnoch | Rebuilds a released product and ties two releases together | Rejected |

**How the sound is made (report §"Four ways to build it").**

| Approach | Trade-off | Outcome |
|---|---|---|
| **Prescribed slip clock**: phase oscillator at the note's pitch, warped cosine, stroke envelope, scripted roughness, two body resonances | ~50 ops per voice and sample; matches the measured harmonics, envelope and HNR; risk "synthesizer-like" | **Built as the prototype; approved by ear [ear]** |
| Pulse train into a membrane mode bank | metallic, gong-like | Rejected by the report |
| Friction loop (elasto-plastic / bow table) on a few modes | 2–4× cost, parameter-sensitive, pads must repeat exactly | Kept as the fallback; not needed after the listening |
| FDTD membrane + tube (Onofrei et al.) | 100× over budget, not recognised by its listeners | Rejected |

## 5. The sound: what one voice does [ear]

`fanfrnoch_spike.cpp` is the reference implementation of one drum. The engine reproduces its
signal path and constants (struct `Voice`, `strike()` and `process()`):

```
strike  per stroke: Vary draws length (±20 %·Vary/0.2·½), level (±1.5 dB·…), pitch (±25 ct·…);
        every second stroke of the drum is Alternate dB quieter and Alt Tune cents off;
        Vel Sens: gain = 1 − VelSens·(1 − velocity); Jump drawn with probability Jump;
        Scrape armed; body filters set (Track: × (f0 / 123.47 Hz)^Track)
hand    rubbing while t < Length (or until note-off with Key Up = Stop);
        envelope = two cascaded one-poles toward 1, τ = Attack / 1.95; after the hand stops,
        both decay with T60 = Release / (1 + 2·Damp)
pitch   −Scoop·exp(−t / (ScoopTime/3)) + Drift·min(1, t/Length) − Drop·(1 − exp(−tRel/15 ms))
        + Jump (step to 12·log2(JumpRatio) after 0.7·Length, 4 ms glide)
        + (offset cents + Wobble · 30 Hz low-passed unit-rms noise) / 100
clock   phase += hz/SR · (1 ± 0.35·Split), alternate periods long/short
shape   s = clamp(Stick − Stick>Level·(1 − env·(0.5 + 0.5·vel))·3, 0.5, 0.97)
        tone = −cos(π·φ/s) for φ < s, −cos(π·(1 + (φ−s)/(1−s))) after; Split also scales
        alternate periods by 1 ± 0.3·Split
creak   impulses at Creak Rate (±30 % jitter) ringing a band-pass at Skin with Q from Creak Ring;
        source = (1 − Creak)·tone + Creak·creak
rub     band-passed noise at max(2·f0, 150 Hz), Q 0.7, level-compensated, × Rub,
        × (0.4 + 0.6·(slipping ? 1 : 0.25)) × (0.5 + 0.5·vel)
scrape  noise through a 2.5 kHz band-pass, × Scrape, decaying with τ = 7 ms
body    x = (source + rub)·env;  out = x + 2·Pot(x)·PotLevel + 2·Skin(x)·SkinLevel + scrape
        × level gain × Shimmer (20 Hz low-passed unit-rms noise, dB) → DC blocker
```

- **Sample rate [call].** The approved renders are 48 kHz without oversampling. The warped
  cosine's harmonics fall fast; the builder measures aliasing at the brightest settings
  (Stick 0.95, 860 Hz, 44.1 kHz) and adds Brumle's 2× stage only if alias products exceed
  −60 dB re the fundamental **[builder]**.
- **Absolute level [call].** The default stroke at full velocity peaks around −6 dBFS; a
  limiter follows the sum, as in Brumle.
- **Randomness [builder].** The engine's generators are reset with the engine so that
  regression references hold. If the engine replaces `std::mt19937` and the
  `uniform_real_distribution` with a cheaper generator, the test suite's copy of the prototype
  is amended the same way, and the amended renders must measure like the approved ones
  (harmonic levels within 1 dB, HNR within 1 dB, same f0 and envelope timings).
- **Control rate [builder].** Anything moved from per-sample to the 16-sample control rate is
  moved in the reference copy too.

## 6. Parameters

One **knob set**; the order is permanent. Defaults are the prototype's `Params`
**[ear for those exercised by the renders; call for the rest]**.

| Section | Identifier | Name | Range | Default |
|---|---|---|---|---|
| Stroke | `attack` | Attack | 5–400 ms (log) | 42 ms |
| Stroke | `length` | Length | 0–2000 ms | 230 ms |
| Stroke | `release` | Release | 0.03–3 s (log), T60 | 0.30 s |
| Stroke | `damp` | Damp | 0–100 % | 0 % |
| Stroke | `keyup` | Key Up | Ignore / Stop | Ignore |
| Stroke | `velsens` | Vel Sens | 0–100 % | 70 % |
| Stroke | `vary` | Vary | 0–100 % | 20 % |
| Hands | `alternate` | Alternate | 0–12 dB | 2 dB |
| Hands | `alttune` | Alt Tune | −100…+100 cents | +10 |
| Pitch | `scoop` | Scoop | 0–12 st | 0 |
| Pitch | `scooptime` | Scoop Time | 10–300 ms (log) | 80 ms |
| Pitch | `drift` | Drift | −3…+3 st | −0.8 |
| Pitch | `drop` | Drop | 0–2 st | 0 |
| Pitch | `wobble` | Wobble | 0–60 cents | 20 |
| Pitch | `jump` | Jump | 0–100 % | 0 % |
| Pitch | `jumpratio` | Jump Ratio | 1.1–2.5 | 1.40 |
| Pitch | `velpitch` | Vel>Pitch | 0–100 cents | 0 |
| Friction | `stick` | Stick | 0.50–0.95 | 0.88 |
| Friction | `stickvel` | Stick>Level | 0–0.10 | 0.03 |
| Friction | `split` | Split | 0–100 % | 0 % |
| Friction | `creak` | Creak | 0–100 % | 0 % |
| Friction | `creakrate` | Creak Rate | 4–40 Hz (log) | 14 Hz |
| Friction | `creakring` | Creak Ring | 10–100 ms | 40 ms |
| Body | `pot` | Pot | 150–1500 Hz (log) | 500 Hz |
| Body | `potq` | Pot Q | 1–20 | 4 |
| Body | `potlevel` | Pot Level | −40…+18 dB, bottom = off | off |
| Body | `skin` | Skin | 100–1500 Hz (log) | 306 Hz |
| Body | `skinq` | Skin Q | 1–40 | 10 |
| Body | `skinlevel` | Skin Level | −40…+6 dB, bottom = off | off |
| Body | `track` | Track | 0–100 % | 0 % |
| Noise | `rub` | Rub | −40…0 dB, bottom = off | −10 dB |
| Noise | `scrape` | Scrape | 0–100 % | 10 % |
| Noise | `shimmer` | Shimmer | 0–3 dB | 0.7 dB |
| Master | `volume`, `pan`, `tune`, `octave` | as Brumle | | 0 |
| Master | `bendup`, `benddown` | Bend Up / Bend Down | 0–24 st / 0–12 st | 12 / 2 |
| Master | `drum` | Drum | One / Many | One |
| Master | `lfostart` | LFO Start | Hit / Free | Hit |
| LFO | `lfo1rate`, `lfo1shape`, `lfo2rate`, `lfo2shape` | as Brumle | | as Brumle |

- The exact ranges of the "bottom = off" knobs, and whether a knob's values are linear or log,
  are **[builder]**, keeping the prototype's defaults exactly reachable.
- Vel>Pitch's identifier is `velpitch`, not `veltune`: that is VEL>Tune's (`vel` + `tune`)
  **[builder, phase 02]**. Phase 02's builder decisions: `phases/02-engine/VERIFICATION.md`.
- **LFO amounts [call]:** targets Pitch (in cents, ±100), Stick, Rub, Pot, Pot Level, Skin
  Level, Wobble, Creak, Split, Volume, Pan. Each voice carries its own LFO phases; with
  LFO Start = Hit a stroke repeats exactly.
- **VEL amounts [call]:** as Brumle's rule (`amount·(1 − velocity)` of the knob's travel;
  Volume scales gain). Targets: every continuous knob of Stroke (not Vel Sens), Hands, Pitch,
  Friction, Body, Noise, plus Volume, Pan, Tune and the LFO rates. Not targets: switches,
  Octave, the bend ranges, the amounts. Identifiers `vel<knob>`, names `VEL>Name`.
- **Wheels [call]:** pitch bend bends the drum by Bend Up / Bend Down (the cuíca's pressing
  hand); the mod wheel adds Rub (up to +20 dB, capped at 0 dB); aftertouch adds Stick (up to
  +0.07). They act on the keyboard set.
- `pan` gives stereo output.

## 7. The two modes

Brumle's §7 applies with these changes:

- **Keyboard mode.** Every MIDI note strikes the keyboard set at the note's pitch. With
  Drum = One (default) all notes are one drum: a new note continues the drum's phase and
  envelope, re-arms the stroke, and Alternate counts across notes. With Drum = Many every note
  number is its own drum (Brumle's one-voice-per-note rule).
- **Pad mode.** Notes 36–51 trigger pads 1–16. Each pad has a frozen knob set, its own note
  and a Group (Off, 1–16). **All pads of one group are one drum [call]:** a hit continues that
  group's drum (phase, envelope, alternation) with the new pad's set and pitch. Group Off: the
  pad is its own drum and a re-hit continues it.
- **Voices.** A pool of 16; each drum holds at most one voice while it sounds, so strokes on
  one drum never pile up. When the pool is full the quietest voice is stolen with a few-ms
  fade. A voice retires after its release has fallen below the floor.
- **Default kit [call]** (pad: program, note, group):
  1–2 Fanfrnoch B2, both group 1 (two hands); 3–4 Fanfrnoch high G3/C4 (G3 ≈ 196 Hz), group 2;
  5–6 Brummtopf C♯3/D♯2, group 3; 7–9 Cuíca F4, G5, Cuíca Whoop G5, group 4;
  10–11 Zambomba A3 without/with jump, group 5; 12 Putipù C2, group 6; 13 Furruco C♯2, off;
  14 Creak B2, off; 15 Flick D♯4, off; 16 Buhai C2, off. The builder may adjust pitches by ear
  of the renders' scores.

## 8. Programs [ear]

Overrides of the defaults, values from `fanfrnoch_spike.cpp`: **Fanfrnoch** (default),
**Fanfrnoch High** (the group render's upper drum: Length 150 ms, Alternate 3 dB),
**Brummtopf**, **Zambomba**, **Zambomba Grave**, **Putipù**, **Cuíca**, **Cuíca Whoop**,
**Furruco**, **Creak**, **Flick**, **Buhai**.

**Acceptance bar.** The engine renders the prototype's scores (every file in `renders/`) at
48 kHz. With the same generators the residual against the reference copy stays below −60 dB
(aim far lower, as Brumle's −113 dB); with amended generators the measurements of §5 hold. The
scores become the first `SoundRegressionTests`, plus a fast alternating group, a scoop, a jump,
creak, split and a held note with Key Up = Stop.

## 9. Architecture

Brumle's targets, renamed: `FanfrnochDSP`, `AudioUnitSDK`, `FanfrnochAU`, `FanfrnochAUView`,
`FanfrnochAUExports`, `FanfrnochCore`, `FanfrnochUI`, `Fanfrnoch`, test-only
`FanfrnochReference` (the prototype, as Brumle's `BrumleReference`).

Changes against Brumle's engine:
1. **The amplitude envelope comes back** (Attack, Length, Release, Damp, Key Up = Stop).
2. **Drums:** a voice belongs to a drum (the keyboard, a note number, a group or a pad); a new
   stroke on a sounding drum continues its voice.
3. **Oversampling only if measured necessary** (§5).
4. New parameter table, programs, default kit and regression scores.

Everything else carries over: the C interface, sample-accurate MIDI, lock-free queues,
17 knob sets addressed by index (keyboard = 0, pads 1–16), AU parameters = the keyboard set,
pads/mode/kit/controllers/presets in use/selected pad in the AU's saved state, programs as
overrides, presets and kits as files shared by the app and the plug-in, MIDI controllers with
learn and a standard CC map **[builder: one CC per keyboard-set knob, as Brumle]**, the app's
audio and MIDI, installing the AU from the app, auval.

## 10. The panel, the art and the website

- The panel is Brumle's `InstrumentPanel` with Fanfrnoch's sections (Stroke, Hands, Pitch,
  Friction, Body, Noise, Master) in a layout the builder balances (Brumle's `SectionLayout`).
- **Art by Codex [author].** Codex draws two concept mockups; the builder picks one and Codex
  then makes the assets (background, drum illustration, logo, knob cap, ornament) into
  `Resources/Art/`, then later the app icon (opaque, full-bleed art compiled with `actool`,
  per the global rule) and the website graphics. Direction for the concepts **[call]**: Czech
  folk Christmas of Chodsko — terracotta clay jug, parchment bladder, horsehair, and indigo
  *modrotisk* (blueprint) ornament; the second concept a warmer variant. No text baked into art.
- Website `docs/` (EN + `docs/cs/`), manual describing every control with screenshots of the
  real app, the download link and the version.

## 11. Phases [call]

| Phase | Goal |
|---|---|
| 01-skeleton | Brumle copied and renamed to Fanfrnoch, new identity, builds, tests green, website placeholder |
| 02-engine | `FanfrnochDSP` per §5–§8, the reference copy, regression tests |
| 03-panel-design | Codex concepts and assets |
| 04-app-and-audiounit | the panel's sections, the kit, presets/kits/MIDI learn adapted, auval, manual EN + CS |
| 05-icon-website | Codex icon and website look, screenshots |
| 06-v1.0.0-release | signed/notarized DMG, appcast, GitHub repo and Release, Pages, catalog — **pushes only after the author's OK** |

Version: the first release is **1.0.0 [call]**: it carries Brumle 1.0's whole feature set,
icon and website (Brumle went 0.1.0 → 1.0.0 the same day for the icon alone).
