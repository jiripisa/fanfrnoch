# Artwork assets for "Fanfrnoch" — concept 1 "Modrotisk"

Use your image generation tool to create the artwork below, then save each as a PNG in the
current working directory with the exact name given. The approved mockups are
`reference/concept-1-keyboard.png` and `reference/concept-1-pads.png`: match their look.

Fanfrnoch is a synthesized Czech friction drum for macOS 26 (app and Audio Unit). The panel is
built in SwiftUI: every label, value, knob pointer/arc, pad, key, menu and button is drawn live
in code with Liquid Glass. You make ONLY the decorative raster art the code places behind or
under them.

**Absolute rule: no text, letters, digits, labels, UI controls, knobs (except the requested
blank cap), pads, keys, buttons, arcs or highlights baked into any image** (the wordmark
"Fanfrnoch" is drawn as live text too).

Palette: midnight indigo `#101D38`, blue glass `#233653`, cream `#F6ECD8`, terracotta
`#D88C5B`, parchment `#DBC79F`. Mood: Czech *modrotisk* (indigo blueprint-dyed cloth with fine
cream/white floral and dot patterns), a warm terracotta clay jug at the centre. Craft-inspired
interpretation, not a claim of a documented historical pattern.

## Deliverables

1. `background.png` — **2200 × 1375** (16:10), opaque. The whole window background: deep
   indigo blueprint-dyed cloth with a fine cloth weave and a sparse, delicate cream floral and
   dot modrotisk pattern, more present toward the outer edges, very faint in the centre. It
   must be calm and dark everywhere so that glass cards and light text on top stay readable; no
   focal object.
2. `drum.png` — **1200 × 1200**, transparent background (real alpha). The fanfrnoch: a
   terracotta clay jug (with a small handle) whose mouth is covered with stretched parchment-like
   pig bladder tied with cord, and two separate tufts of dark horsehair emerging upward through
   the centre of the skin, as in the mockups. Three-quarter view, slightly from above, whole
   object within generous margins, soft contact shadow allowed, no background, no table.
3. `logo.png` — **512 × 512**, transparent background. A simple emblem of the jug with its two
   horsehair tufts in cream/parchment (as the small jug left of the wordmark in the mockup),
   strong silhouette usable at 40 pt. No text.
4. `knob.png` — **512 × 512**, transparent background. A round knob cap seen straight from
   above: dark pearl-graphite with a soft warm sheen and a fine bevel ring, soft drop shadow
   inside the canvas. **Rotationally symmetric, with NO pointer, notch, tick or marking**,
   centred, cap diameter about 80 % of the canvas (code draws the pointer and value arc).
5. `ornament.png` — **2400 × 64**, transparent background. A horizontal band of cream
   modrotisk floral-and-dot ornament (as the dividers under the header and above the keyboard
   in the mockups) that tiles seamlessly left-to-right (the right edge must continue the left
   edge).

## Process

- Generate, then normalise each file to the exact pixel size with macOS `sips`, keeping
  transparency where required.
- Check alpha: `sips -g hasAlpha <file>` must say yes for 2–5, with real zero-alpha pixels
  around the objects (no checkerboard painted in).
- Composite the assets on the background in the mockup's layout as a check (keep that
  composite as `composite-check.png`) and fix anything that looks wrong: fringes, a cap that
  is not symmetric, an ornament seam.
- Write `assets.md`: one line per file (size, alpha, what it is), plus any choices you made,
  and the generation prompts.

Your image tool's automatic staging under `$CODEX_HOME/generated_images/` is fine: copy the
final PNGs from there into the current directory. Apart from that, write nothing outside the
current working directory. Do not stop to ask questions: make sensible choices and note them
in `assets.md`.
