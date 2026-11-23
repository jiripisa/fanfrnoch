# Image-generation prompt set

Tool: built-in `image_gen.imagegen`; no CLI/API fallback.

## Shared keyboard-generation specification

Use case: ui-mockup. Create a polished, pixel-sharp, straight-on UI screenshot for Fanfrnoch, a native macOS 26 Liquid Glass musical instrument and Audio Unit. Single complete app window, landscape EXACTLY 16:10, preferably 1600x1000 pixels. Fill frame with app, no desktop, perspective, laptop, poster captions, or mockup presentation. Dense but extremely legible professional music software. The sibling Brumle layout is header then titled rounded glass cards with knobs, then performance area beneath. Preserve that structure, but Fanfrnoch is its own product. ALL text must be precisely spelled and readable. Small modest knob caps, high contrast labels above and numeric values below; no giant dials. Modern translucent softly rim-lit dark glass cards, carefully aligned grid, restrained reflections, fine hairline separators. No old-fashioned 2005 hardware rack screws.
Layout: header y=0..100. Seven section cards y=118..700, in TWO rows plus full-height Master at right. Left three quarters width: upper row Stroke (3 columns x 2 knobs), Hands (2 knobs), Pitch (4 columns x 2 knobs). Lower row Friction (3 columns x 2), Body (4 columns x 2 with final empty cell), Noise (3 knobs). Right quarter Master full height, 2 columns x 4 knob rows, then menus and switches. This is 40 knobs total. All seven sections and all controls visible without scrolling.
HEADER exact: small jug emblem; large wordmark "Fanfrnoch"; Program menu value "Fanfrnoch"; Preset menu value "Koleda"; segmented "Keyboard | Pads"; buttons "LFO 1", "LFO 2", "VEL", "MIDI", settings gear.
EXACT CARD CONTENT, each listed label appears once within its section, a circular knob per parameter, label ABOVE knob, value BELOW:
Stroke: Attack / 42 ms; Length / 230 ms; Release / 0.30 s; Damp / 0 %; Vel Sens / 70 %; Vary / 20 %. Bottom segmented switch caption "Key Up", choices "Ignore | Stop", Ignore selected.
Hands: Alternate / 2.0 dB; Alt Tune / +10 ct.
Pitch: Scoop / 0 st; Scoop Time / 80 ms; Drift / −0.8 st; Drop / 0 st; Wobble / 20 ct; Jump / 0 %; Jump Ratio / 1.40; Vel>Pitch / 0 ct.
Friction: Stick / 0.88; Stick>Level / 0.03; Split / 0 %; Creak / 0 %; Creak Rate / 14 Hz; Creak Ring / 40 ms.
Body: Pot / 500 Hz; Pot Q / 4.0; Pot Level / Off; Skin / 306 Hz; Skin Q / 10; Skin Level / Off; Track / 0 %.
Noise: Rub / −10 dB; Scrape / 10 %; Shimmer / 0.7 dB.
Master: Volume / 0.0 dB; Pan / 0 %; Tune / 0 ct; Octave / 0; Bend Up / 12 st; Bend Down / 2 st; LFO 1 Rate / 6.00 Hz; LFO 2 Rate / 2.00 Hz. Below knobs small menus "LFO 1 Shape" value "Sine", "LFO 2 Shape" value "Sine". Segmented "Drum: One | Many", One selected; segmented "LFO Start: Hit | Free", Hit selected.
FANFRNOCH ARTWORK: small lovingly rendered realistic terracotta clay jug with stretched parchment-colored leather covering mouth, tied with cord, TWO clearly separate tufts/bundles of dark horsehair emerging through the CENTER of that skin. No wooden stick, no jaw harp, no bongo, no metal strings. The two hair bundles are essential. Artwork belongs decoratively in lower performance area, not obscuring controls.

## Concept 1 style

CONCEPT 1 — MODROTISK. Deep midnight indigo blueprint-dyed cloth ground #101D38, fine sparse white floral and dot modrotisk folk pattern visible at perimeter and gutters. Blue glass cards #233653 with dark opaque-under-text areas, warm cream text #F6ECD8. Warm terracotta #D88C5B knob arcs and selections, parchment #DBC79F accents. Knob caps modest pearl graphite with warm center sheen. Restrained delicate white Czech floral bands. Editorial warm serif wordmark and section headings, highly legible SF Pro-style sans controls, tabular numbers. Crisp contemporary craft with cool blue atmosphere and warm clay drum. Dark background, no teal.
## Concept 2 style

CONCEPT 2 — KOLEDA. Clearly DIFFERENT from indigo concept: warm winter-night smoky espresso wood and dark glazed earthenware ground #211A17, brown smoke translucent glass cards #3B3029, parchment cream text #F5E7CC. Candle-warm ochre #E5AD58 arcs and selected controls, glazed terracotta #B96543 highlights, muted red #B7473E with cream #E8DDC5 in a narrow red-and-white geometric Chod embroidery band. Subtle wood grain and ceramic glaze in margins, no blue. Soft amber edge light, restrained candle glow. Warm handsome serif wordmark and section titles, SF Pro-style control labels and tabular values. Contemporary Mac glass panels over folk craft materials, not rustic hardware.
## Keyboard performance area

PERFORMANCE AREA y=720..1000: keyboard mode. Header segmented Keyboard is selected. One wide rounded glass card; top part contains title "Keyboard", narrow folk ornament band, decorative friction-drum illustration, "Last note" readout "C3" and "Send to pad" button. Bottom part is a continuous correctly patterned 3-octave piano keyboard, ivory and dark keys, octave labels C2 C3 C4. No pads.
## Pad performance area

PERFORMANCE AREA y=720..1000: pad mode. Header segmented Pads selected. Left 72% contains EXACTLY 16 pads in a 4 columns by 4 rows grid, equal size modern softly rounded glass MPC pads, each has number and name plus pitch and mute group. Right 28% is small inspector with drum artwork, title "Pads", text "Selected: 05 · Cuíca Whoop", menus "Pitch" value "B2", "Group" value "3", "Kit" value "Koleda". Pad 05 is selected with warm outline and glow.
Exact pad grid reading order:
01 Fanfrnoch / C2 G1; 02 Fanfrnoch High / C3 G1; 03 Brummtopf / D2 G2; 04 Cuíca / G3 G3;
05 Cuíca Whoop / B2 G3; 06 Zambomba / C2 G4; 07 Putipù / D3 G4; 08 Furruco / F2 G5;
09 Creak / G2 G6; 10 Flick / A3 G6; 11 Buhai / B1 G7; 12 Fanfrnoch / D2 G1;
13 Brummtopf / A2 G2; 14 Cuíca / C4 G3; 15 Zambomba / G2 G4; 16 Furruco / C3 G5.
No keyboard.
## Edit constraints

For each pad view, use its corresponding generated keyboard screenshot as the edit target. Preserve the complete upper control region, every label and value, layout, wordmark, materials, colors, typography, and framing. Select Pads in the header and replace only the bottom performance card with the specified 4 × 4 pad grid and inspector. Preserve Modrotisk's floral divider and Koleda's red-and-white embroidery as a compact band.

For the final Koleda pad correction, change only the bottom-right drum illustration: remove detached hair below the jug and place two separate bundles emerging upward through the center of its stretched skin. Shrink the jug slightly if necessary to keep the inspector title and controls unobscured. Preserve all other content.

