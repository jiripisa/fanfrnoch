# Design concepts for "Fanfrnoch" — a synthesized friction drum for macOS

Use your image generation tool to create UI mockups, then save them as PNG files in the
current working directory with the exact names given below.

## The product

Fanfrnoch is a software instrument: a native macOS 26 app and an Audio Unit plug-in that shows
the same window inside music hosts (Ableton Live, Logic Pro). It synthesizes a **friction
drum** and is used mainly for rhythm. The name is the Czech folk friction drum "fanfrnoch"
(also "bručák"): a **clay jug or pot covered with a stretched pig bladder or leather, with two
bundles of horsehair passing through the middle of the skin**; the player pulls the horsehair
with wet hands, alternately, and the drum gives a deep, bellowing, rhythmic grunt. It
accompanied Christmas and New Year carolling in Chodsko (south-west Bohemia).

It is the sibling of an existing app, "Brumle" (a synthesized jaw harp). Its window is in
`reference/sibling-app-brumle-window.png` (keyboard mode) and
`reference/sibling-app-brumle-pads.png` (pad mode). **Keep that window's structure**: header,
titled knob sections in Liquid Glass cards, the mode area below. Fanfrnoch must look clearly
like its own product, with a different palette, materials, ornament and drum artwork.

## What the window must show (every mockup must contain these, legibly)

**Header bar:** the "Fanfrnoch" wordmark with a small emblem; a Program menu (value
"Fanfrnoch") and a Preset menu (value "Koleda"); a segmented switch **Keyboard | Pads**;
buttons **LFO 1**, **LFO 2**, **VEL**, **MIDI**; a settings gear.

**Knob sections, each titled, every label once, each knob with its name above and value below:**
- **Stroke:** Attack 42 ms, Length 230 ms, Release 0.30 s, Damp 0 %, Vel Sens 70 %, Vary 20 %,
  and a 2-way switch **Key Up: Ignore | Stop**.
- **Hands:** Alternate 2.0 dB, Alt Tune +10 ct.
- **Pitch:** Scoop 0 st, Scoop Time 80 ms, Drift −0.8 st, Drop 0 st, Wobble 20 ct, Jump 0 %,
  Jump Ratio 1.40, Vel>Pitch 0 ct.
- **Friction:** Stick 0.88, Stick>Level 0.03, Split 0 %, Creak 0 %, Creak Rate 14 Hz,
  Creak Ring 40 ms.
- **Body:** Pot 500 Hz, Pot Q 4.0, Pot Level Off, Skin 306 Hz, Skin Q 10, Skin Level Off,
  Track 0 %.
- **Noise:** Rub −10 dB, Scrape 10 %, Shimmer 0.7 dB.
- **Master:** Volume 0.0 dB, Pan 0 %, Tune 0 ct, Octave 0, Bend Up 12 st, Bend Down 2 st,
  LFO 1 Rate + LFO 1 Shape (small menu "Sine"), LFO 2 Rate + LFO 2 Shape, a switch
  **Drum: One | Many** and a switch **LFO Start: Hit | Free**.

That is about 40 knobs: denser than the sibling. They must stay readable (modest knob caps,
strong contrast for labels and values). Arrange the seven sections in a balanced grid (for
example two rows of cards); every control must be visible.

**Mode-specific area, below the knobs:**
- *Keyboard mode:* a two-to-three-octave on-screen piano keyboard strip, a "Last note" readout
  and a **Send to pad** button, with the drum artwork placed decoratively in this area as the
  sibling places its jaw harp.
- *Pad mode:* a **4 × 4 grid of 16 pads**, MPC-style. Each pad shows its number, the sound's
  name (Fanfrnoch, Fanfrnoch High, Brummtopf, Cuíca, Cuíca Whoop, Zambomba, Putipù, Furruco,
  Creak, Flick, Buhai), its pitch (e.g. "B2") and its mute group (e.g. "G1"). One pad is
  selected; beside the pads a small inspector shows the selected pad's Pitch and Group, and a
  Kit menu.

## Look and feel

- **Motif:** the fanfrnoch itself (terracotta clay jug, stretched parchment-like bladder tied
  with cord, two tufts of dark horsehair) and Czech folk craft of Chodsko: indigo
  **modrotisk** (Czech blueprint-dyed cloth with small white floral and dot patterns), red and
  white Chod embroidery, glazed folk pottery, winter carolling at night.
- **macOS 26 "Liquid Glass":** translucent glass cards, segmented controls and buttons floating
  over the artwork. A modern Mac app, not a 2005 skeuomorphic plug-in.
- Controls clearly usable: high contrast for labels and values, knobs that read at a glance.

## Deliverables

Make **two clearly different concepts**:
1. **"Modrotisk"** — deep indigo blueprint cloth with fine white folk pattern as the ground,
   warm terracotta clay and parchment accents, cream text, a warm accent colour for arcs.
2. **"Koleda"** — a warmer winter-night variant: smoky dark wood or dark glazed earthenware,
   terracotta and ochre, red-and-white Chod embroidery band, candle-warm accents.

If you have a better idea for one of them, use it, but keep two strong, distinct concepts.

For each concept, create two images at landscape 16:10 (about 1600 × 1000) and save them as:
- `concept-1-keyboard.png`, `concept-1-pads.png`
- `concept-2-keyboard.png`, `concept-2-pads.png`

Then write `concepts.md` with a short section per concept: its name and idea; the palette (hex
values); the materials and ornament; the typography; which parts would be **raster artwork**
(background, drum illustration, logo, knob caps, ornament bands) and which **native SwiftUI /
Liquid Glass controls**.

Your image tool's automatic staging of generated images under `$CODEX_HOME/generated_images/`
is fine: copy the final PNGs from there into the current directory under the names above.
Apart from that staging, write nothing outside the current working directory. Do not stop to
ask questions: make sensible choices and note them in `concepts.md`.
