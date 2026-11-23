# Phase 04 — Verification (2026-11-24)

The panel of the app and of the plug-in is concept 1 "Modrotisk": the palette, two rows of section
cards with Master the full height on the right, the footer of either mode with the upright drum.
Presets, kits and MIDI learn were driven in the real app; the manual describes the friction drum in
English and Czech with pictures of the real app. Code checks ran on `600f990` (the last code
commit; later commits change tests' example names, documentation and planning only, and the suite
was run again after them).

| Check | Result |
|---|---|
| `swift test` | `✔ Test run with 290 tests in 33 suites passed after 15.950 seconds.` No `✘` or `warning:` line (284 before the phase; `SectionLayoutTests` has 13 tests instead of 7) |
| `swift test --sanitize=thread` | `✔ Test run with 290 tests in 33 suites passed after 105.092 seconds.` No ThreadSanitizer report |
| `./build.sh release` | `Build complete: …/build/release/Fanfrnoch.app`, no `warning:` |
| `codesign --verify --deep --strict build/release/Fanfrnoch.app` | passes |
| `nm -gU …/Fanfrnoch.component/Contents/MacOS/Fanfrnoch` | one symbol: `T _FanfrnochAUFactory` |
| `auval -v aumu Fanf JPis` | `AU VALIDATION SUCCEEDED.` 103 of 103 parameters PASS, `Cocoa Views Available: 1`, `Component Version: 0.1.0 (0x100)`. The release component was copied to `~/Library/Audio/Plug-Ins/Components/`, found after `auval -a`, and removed afterwards |
| Every control on the panel | `SectionLayoutTests`: every parameter of every section is laid out exactly once, every section is on the panel once (an unknown one joins the last row), no row holds more cells than its columns |
| The app, started by its path | `build/release/Fanfrnoch.app/Contents/MacOS/Fanfrnoch`; window 1100 × 764 pt with the title bar (content 1100 × 732), not resizable, the same size in both modes |
| Screens of the real app | window captured by the id `CGWindowListCopyWindowInfo` gives for the launched pid, `screencapture -x -o -l`; menus and popovers by the id of the process's front window (on macOS 26 the capture holds the whole window group). Looked at: keyboard mode, pad mode, LFO 1 and VEL amounts, MIDI with Stick listening, the Program, Preset and Kit menus, the name popover, Send to pad |
| The plug-in's window | a scratch host (in the session's scratchpad) opened the installed component in process, took `FanfrnochAUViewFactory` from `kAudioUnitProperty_CocoaUI` and showed its view: 1100 × 732, the artwork from the component's bundle, no gear, keyboard and pad mode |
| Presets through the UI | Save as… → "Wet hands" wrote `~/Library/Application Support/Fanfrnoch/Presets/Wet hands.fanfrnoch` (values by identifier); a second preset "Slow growl" from Putipù; loading "Wet hands" back ticks it and puts back its values (the LFO amounts set after saving went) |
| Kits through the UI | Save kit as… → `Kits/Two hands.fanfrnochkit` and `Samba.fanfrnochkit`; both listed in the Kit menu with Default kit, Save kit as…, Delete kit |
| MIDI learn through the UI | MIDI on shows the standard map (Attack CC 73, Length 14, Release 72, … Stick 74, Pot Q 71, Rub 2, Volume 7, Pan 10, LFO 2 Shape 115); a click on Stick shows the dashed terracotta ring and "move a control" |
| Pad names | the default kit's tiles read their programs (01 Fanfrnoch … 16 Buhai; pads 10 and 11 both "Zambomba"); `KitTests.padNames` |
| File names and saved state | `PresetLibraryTests` (`.fanfrnoch`), `KitTests` (`.fanfrnochkit`), `AudioUnitTests` round trips of `fanfrnoch-pads` and `fanfrnoch-controllers`; `ControllerTests` pin the standard map of phase 02 |
| Manual | `docs/manual.html` and `docs/cs/manual.html` have the same 1852 tags in the same order (language attributes aside); ten pictures in `docs/assets/manual/` (2200 px wide for the window, 64 levels per channel, each under 0.91 MB); every figure was rendered alone in headless Chrome and its marks checked against the controls |
| Leftovers | `grep -rniE` for khomus, chomus, jaw harp, Brumle, reed, mouth, vowel, Polar, harp, Morsing, Molln, Genggong, twang, drone, curve, aurora, bone and silver over `Sources`, `Tests`, `Resources`, both manuals, `build.sh`, `scripts`, `run.sh`, `.claude`: only words that contain them match: "sharp", "cSharp", "bipolar", "freed", "agreed" |
| Clean-up | the app, the scratch host and headless Chrome quit; `defaults delete io.jp4.fanfrnoch`; removed `~/Library/Preferences/io.jp4.fanfrnoch.plist`, `~/Library/Application Support/Fanfrnoch`, `~/Library/Caches/io.jp4.fanfrnoch`, `~/Library/HTTPStorages/io.jp4.fanfrnoch` and the component; the scratch host wrote no preferences (`defaults read auhost`: domain not found) |

Final screens: `docs/assets/manual/keyboard.png` (keyboard mode) and `docs/assets/manual/pads.png`
(pad mode, pad 05 selected).

## Decisions [builder]

- **Palette** (`Artwork`): `indigo` #101D38 (glass tint, dark text on lit controls, black keys),
  `glass` #233653 (cards and pad tiles), `cream` #F6ECD8 (wordmark, titles, names), `terracotta`
  #D88C5B (value arcs, chosen segment, selected pad, held key, listening), `parchment` #DBC79F
  (values, captions, a pad's second line).
- **LFO and VEL colours:** LFO 1 light sky blue #8EC9EF, LFO 2 mint #93D6B4, VEL parchment
  #DBC79F. Terracotta, the brief's example, is the knobs' own value arc, so the sources take two
  cool colours and the warm skin colour; all three read on indigo.
- **Layout in the core:** `SectionLayout` gained a `rule` row (Master's two thin lines) and the
  mockup's columns; the new `PanelLayout` puts the cards and gives a row's cards widths in
  proportion to their columns. Hands and Noise centre their one row of knobs, as the mockup does.
- **Window 1100 × 732 pt** (764 with the title bar), 27 pt taller than Brumle's 705: two rows of
  cards and Master's four rows of knobs plus four switch rows. Knobs are compact for it (a 44 pt dial,
  a 33 pt cap). It fits a 1440 × 900 screen.
- **Switches in rows of their own** show their name on the left (Key Up, the LFO shapes, Drum,
  LFO Start), as in the mockup; the shapes are small glass menus.
- **The footer is one glass card** in either mode; the pad tiles are plain fills on it (no glass on
  glass), so the selected pad's terracotta outline shows.
- **The drum** is cropped to its alpha bounds (measured: x 293…920, y 147…1054 of 1200 px). In
  keyboard mode it stands on the keys and reaches 30 pt above the footer card's edge; beside the pad
  inspector it is 96 pt tall. It never takes a click. The logo is cropped the same way.
- **The Kit menu is titled "Load or save"**: no kit is "in use" (the mockup's kit name has nothing
  behind it in the model).
- **Send to pad** opens to the left of its button (centred over it, it hung past the window's right
  edge) with tiles 132 pt wide, names shrinking to 80 % at most ("03 Fanfrnoch High" was cut short).
- **Group help text:** a group is one drum ("its pads are one drum, and a hit on any of them goes on
  from where that drum is"), no longer a mute group.
- **Manual pictures** go into `docs/assets/manual/` (also the main window, `keyboard.png`);
  `docs/assets/fanfrnoch-window.png` stays for `docs/index.html` and phase 05. Czech uses "tah"
  for a stroke.
- **Pictures with the window inactive:** the app was not brought to the front for them, so no
  keyboard-focus ring shows on the Program menu (it does on an active window with keyboard
  navigation on) and the author's work in front was not interrupted.

## Deviations

- The window is 732 pt tall, not about 705 (above).
- The Send to pad popover's bottom edge, with a pad chosen, lies about 10 pt below the window's
  (it is a window of its own and shows over whatever is below).
- No piano strip glow of a held key or a lit pad was seen: no key or pad was clicked with the mouse
  (the author was using the Mac; a click would have sounded through the speakers and needed the app
  in front). Pads were selected through their accessibility action.

## Not verified

- **Sound:** nothing was played or heard in this phase; the engine is unchanged since phase 02.
- **Mouse gestures:** dragging a knob, clicking keys and pads, Send to pad's Replace (cancelled in
  the picture; the copy is covered by tests), loading a kit from the menu, deleting a preset or kit.
- **Settings** sheet: not opened.
- **A real host** (Logic, Live) and **real MIDI hardware**: only auval and the scratch host; no CC
  was sent to the learning knob.
- **The active window's look** was seen only in the first screens (before the pictures), with the
  focus ring on the Program menu once keyboard focus had moved there.
- `docs/assets/site.css` and `manual.css` still open with a "Polar Khomus" comment, and
  `docs/index.html` (EN and CS) is still the jaw harp's: phase 05 rewrites the website.
