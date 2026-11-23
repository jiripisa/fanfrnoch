# Fanfrnoch design concepts

Both concepts retain Brumle's header, titled control cards, and lower performance area. The denser instrument uses two rows of cards with a full-height Master card on the right. All 40 knobs remain visible. The keyboard and pad variants retain their concept's control layout.

## 1. Modrotisk

Files: [Keyboard](concept-1-keyboard.png) · [Pads](concept-1-pads.png)

**Idea:** a cool indigo cloth setting with warm clay at its center. Fine cream floral and dotted ornament frames translucent blue cards. Terracotta arcs connect the controls to the illustrated friction drum; the selected pad uses the same warm accent.

**Palette:** midnight indigo `#101D38`, blue glass `#233653`, cream text `#F6ECD8`, terracotta accent `#D88C5B`, parchment `#DBC79F`. These are intended implementation colors; rendered lighting adds variations.

**Materials and ornament:** blueprint-dyed cloth, delicate white floral borders, softly reflective dark knob caps, blue-tinted glass, and a terracotta jug with cord-bound parchment skin and two dark horsehair bundles. Keep the floral detail outside label areas.

**Typography:** a substantial warm serif for the wordmark and section headings; SF Pro-style sans serif for controls, menus, and values. Use monospaced digits for stable numeric readouts. New York and SF Pro are the intended native implementation pairing; the generated lettering is a visual approximation.

**Raster artwork:** cloth texture, drum illustration, floral ornament strips, and a small static knob-cap shading texture if needed. The jug emblem may be delivered as a transparent raster asset; render the wordmark as live text. Keep all artwork independent of control labels.

**Native SwiftUI / Liquid Glass:** cards, menus, segmented pickers, buttons, settings symbol, keyboard, pads, inspector, selection highlights, labels, and values. Knobs should be custom accessible SwiftUI controls with live arcs and indicators; a decorative raster cap must not contain state. Use restrained glass tint and sufficient backing opacity to preserve contrast.

## 2. Koleda

Files: [Keyboard](concept-2-keyboard.png) · [Pads](concept-2-pads.png)

**Idea:** candle-warm winter carolling, with smoky brown glass over dark wood and glazed earthenware. A red-and-white embroidery band gives this concept a distinct folk identity. Amber arcs and a warm selected-pad glow carry the active state.

**Palette:** espresso ground `#211A17`, smoke-brown glass `#3B3029`, parchment text `#F5E7CC`, candle ochre `#E5AD58`, glazed terracotta `#B96543`, embroidery red `#B7473E`, embroidery cream `#E8DDC5`.

**Materials and ornament:** subtle wood grain, dark ceramic glaze, translucent brown cards, restrained amber edge light, and a narrow Chod-inspired embroidery band. The jug is glossy terracotta with a tied skin and two horsehair bundles emerging through its center. Ornament is a concept interpretation rather than a reproduction of a documented historical textile.

**Typography:** the same serif/sans hierarchy as Modrotisk preserves the sibling-product connection. Cream headings and plain, high-contrast sans serif labels keep the warmer materials from competing with control readability.

**Raster artwork:** wood/glaze background, glazed drum illustration, embroidery strip, and optional subtle knob-cap texture. The outline jug emblem can be a small transparent raster asset; keep the wordmark as live type.

**Native SwiftUI / Liquid Glass:** all interactive surfaces and text, including glass cards, menus, switches, knobs and their arcs, keyboard keys, pads, inspector, and focus/selection states. The embroidery and drum remain decorative assets behind or beside those controls.

## Choices and delivery

- LFO rates use 6.00 Hz and 2.00 Hz, following the sibling reference; both shape menus show Sine.
- Default switches show Key Up: Ignore, Drum: One, and LFO Start: Hit.
- Keyboard views show Last note C3 and approximately three octaves starting at C2.
- Pad views use all eleven requested sound names across sixteen slots, with repeated sounds assigned different pitches. Pad 05, Cuíca Whoop, is selected at B2 in group 3; the Kit menu shows Koleda.
- Artwork and UI mockups were made with the built-in image-generation tool. Pad views were edited from their corresponding keyboard views to preserve visual continuity. Koleda's pad drum received a targeted correction to attach both hair bundles to the skin.
- Native PNG sizes are 1586 × 992 for both keyboard views and Koleda pads, and 1585 × 992 for Modrotisk pads: approximately 1600 × 1000 and 16:10. They are saved without resampling.
- The prompt set is recorded in [generation-prompts.md](generation-prompts.md). These PNGs are visual concepts; native control behavior and accessibility are implementation work.
