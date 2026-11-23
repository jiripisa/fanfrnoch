# Phase 04 — the app and the Audio Unit's panel: Plan

**Goal:** the panel of the app and of the plug-in looks and works like the approved mockups of
concept 1 "Modrotisk" (`.planning/design/concepts/concept-1-keyboard.png`, `concept-1-pads.png`):
the Modrotisk palette, two rows of section cards with a full-height Master card, the footer of
either mode with the upright drum; presets, kits and MIDI learn checked against the new table;
the manual rewritten for the friction drum in English and Czech, with pictures of the real app.

**Spec:** `.planning/specs/2026-11-23-instrument-design.md` §6, §7, §10. Phase 02's builder
decisions: `phases/02-engine/VERIFICATION.md`; the art: `phases/03-panel-design/`. Pattern:
Brumle's phases 04 and 05 (`../Brumle/.planning/phases/04-app-and-audiounit/`,
`05-presets-kits-midi-learn/`) and its manual (`../Brumle/docs/manual.html`, `docs/cs/manual.html`).

**Branch:** `feature/04-app-and-audiounit` from `main`; merged back with `--no-ff` at the end of
the phase (not by this plan's builder). Never pushed.

## Global constraints

- The Audio Unit's identity and the parameter table do not change (CLAUDE.md).
- Logic goes into `FanfrnochCore`, test first; `FanfrnochUI` stays a thin layer.
- The app is launched by its path, never by its name; its window is captured by the window id of
  the process that was launched (`CGWindowListCopyWindowInfo`, `kCGWindowOwnerPID`), never the
  screen. Scratch helpers live in the session's scratchpad and leave nothing behind.
- Conventional Commits with a scope, no AI attribution; `git status` before every commit.

## Tasks

1. **Where the cards go** (`FanfrnochCore/SectionLayout.swift`): each section's grid as the
   mockup draws it (Stroke 3 columns with Key Up in a row of its own, Hands 2, Pitch 4,
   Friction 3, Body 4, Noise 3, Master 2 with the LFO shapes, Drum and LFO Start as labelled
   rows), where a thin rule separates rows of another kind, and a `PanelLayout`: two rows of
   cards (Stroke | Hands | Pitch over Friction | Body | Noise) and Master on the right, the
   cards of a row sharing its width in proportion to their columns. A section the panel does not
   know still shows. Test: `SectionLayoutTests`.
2. **Palette and type** (`Artwork.swift` and every use): indigo `#101D38`, glass `#233653`,
   cream `#F6ECD8`, terracotta `#D88C5B`, parchment `#DBC79F`; three distinct colours for LFO 1,
   LFO 2 and VEL that read on indigo. New York for the wordmark, titles and pad names, SF Pro
   for controls, monospaced digits for values.
3. **The panel** (`InstrumentPanel`, `SectionView`, `KnobView`, `HeaderView`): the cards of
   Task 1 with a compact knob, the header and the ornament bands of the mockup, a window of about
   Brumle's size (1100 × 705 pt).
4. **The footer** (`ModeFooterView`, `PadGridView`, `PadInspectorView`, `DrumView`): keyboard
   mode "Keyboard", ornament, the upright drum, Last note, Send to pad and three octaves of keys;
   pad mode the 4 × 4 pads (number, name from the program or preset, pitch, group) and the
   inspector (drum, Selected, Pitch, Group, Kit). `DrumView` crops the jug to its real bounds and
   never takes a click. A group is one drum: the help texts say so.
5. **Presets, kits, MIDI learn:** the inherited tests pass against the new table; the files are
   `*.fanfrnoch` and `*.fanfrnochkit` in `~/Library/Application Support/Fanfrnoch/`, the AU's
   state keys are `fanfrnoch-pads` and `fanfrnoch-controllers`, the standard CC map is
   phase 02's; pad names come from programs.
6. **Checks:** `swift test`, `swift test --sanitize=thread`, `./build.sh release`,
   `auval -v aumu Fanf JPis`; the real app run by path and looked at in both modes, fixed until it
   reads like the mockup; the plug-in's window in a scratch host.
7. **The manual** (`docs/manual.html`, `docs/cs/manual.html`): Brumle's structure tag for tag,
   rewritten for Fanfrnoch: every control of every section, both modes, pads and groups, Drum One
   and Many, Send to pad, presets, kits, MIDI learn, the LFO and VEL amounts, settings, installing
   the Audio Unit, the programs and the default kit. Pictures of the real app in
   `docs/assets/manual/`; Brumle's that no longer apply go. `docs/index.html` stays for phase 05.
8. **Leftovers:** no khomus, jaw harp, Brumle, reed, mouth, vowel or Polar in `Sources/`,
   `Tests/`, `Resources/`, the manual, `build.sh` and `scripts/`.
9. **Close:** CHANGELOG lines, `VERIFICATION.md`, `ROADMAP.md`, `STATE.md`.

## Acceptance

- Every control of the parameter table that Brumle's panel showed is on the panel (tested), and
  both modes look like the mockups in screenshots of the real app.
- `swift test` green, TSan clean, the release build and `auval` pass.
- The manual describes Fanfrnoch only, EN and CS with the same tags.
