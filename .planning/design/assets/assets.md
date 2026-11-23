# Fanfrnoch artwork assets — Modrotisk

- `background.png` — 2200 × 1375, RGB / opaque, midnight-indigo cloth with sparse cream corner florals.
- `drum.png` — 1200 × 1200, RGBA / real transparency, terracotta friction drum with tied parchment skin, small handle and two separate horsehair tufts.
- `logo.png` — 512 × 512, RGBA / real transparency, flat cream jug emblem with two tufts and a transparent handle opening.
- `knob.png` — 512 × 512, RGBA / real transparency, blank radial graphite cap with a fine concentric bevel and no pointer or markings.
- `ornament.png` — 2400 × 64, RGBA / real transparency, seamless cream floral, leaf and dot band.
- `composite-check.png` — 2200 × 1375, RGBA / fully opaque pixels, decorative assets placed on the background in the approved keyboard mockup's approximate layout.

## Choices and processing

Generated five separate assets using the built-in image generation tool after inspecting both supplied reference mockups. No external image-generation API or fallback CLI was used. The images are craft-inspired interpretations, not documented historical patterns. All text and interactive UI remain absent.

The background is deliberately sparse and quiet through the center. Cream motifs are concentrated at the corners. The jug uses restrained cream botanical decoration, a right-hand handle and two separated tufts. Additional transparent padding keeps the entire object and hairs inside generous margins. No table or contact shadow was added.

The emblem was flattened to cream #F6ECD8 and isolated alpha-extraction specks were removed before downsampling. Its main generated silhouette and skin/cord details were retained.

The generated cap was radially averaged to eliminate directional lighting and irregularities. All shading is a function of distance from the center; no pointer, notch, tick, dot or value arc is present. Its visible diameter is approximately 81% of the canvas.

The ornament uses a 200-pixel segment of generated flowers, leaves and dots, reflected to form a 400-pixel repeat, repeated six times. The original line was cropped from its transparent canvas; low-alpha dust and colored extraction fringes were removed and the ink was flattened to cream. Reflection at open gaps provides seamless repeats. Transparent margins remain above and below.

`prepare-assets.swift` uses macOS CoreGraphics/ImageIO for alpha inspection, padding, deterministic cleanup, radial averaging, tiling and compositing. No existing project utility was available, and sips alone does not provide pixel-level alpha checks, radial averaging or compositing. The prepare mode expects copies of the original generated images; do not rerun it on already processed deliverables. The inspect, composite and verify modes can be run on final files.

Final sizes were normalized with macOS sips:

```sh
sips -z 1375 2200 background.png
sips -z 1200 1200 drum.png
sips -z 512 512 logo.png knob.png
sips -z 64 2400 ornament.png
```

The composite contains only the requested decoration and instances of the blank cap. Cap groups follow the mockup's Stroke, Hands, Pitch, Master, Friction, Body and Noise positions; ornament lies below the header and above the lower area; the jug sits at the lower center. Labels, panels, keys, pads and live controls are intentionally not rasterized. This is an artwork placement/edge check, not a screenshot of the SwiftUI application.

## Validation

`sips -g pixelWidth -g pixelHeight -g hasAlpha` confirms every final size and hasAlpha=yes for drum, logo, knob and ornament; background hasAlpha=no.

Pixel checks found 1,056,120 zero-alpha pixels in drum, 204,721 in logo, 112,360 in knob and 122,748 in ornament. Background has 3,025,000 opaque pixels and no transparency. These are actual transparent pixels, not a painted checkerboard.

Final knob quarter-turn comparison: maximum difference 1/255 per channel after sips resampling. Ornament first/last columns: maximum difference 0/255, including alpha. The generated radial cap is rotationally symmetric before normal resampling quantization.

Visually inspected final assets and the composite on indigo for unwanted marks, fringe visibility, hair separation, emblem clarity, cap shading and ornament continuity.

## Generation prompts

### background.png

Create a production decorative raster asset background.png for the Fanfrnoch music instrument app, approved Czech modrotisk style. Landscape 16:10, target 2200x1375. Opaque midnight indigo #101D38 blueprint-dyed cloth, subtle fine cloth weave, very sparse small delicate cream #F6ECD8 botanical flowers and dots mainly at the extreme outer edges, nearly invisible in the central 85 percent. Match refined dark navy cloth and tiny cream folk sprigs in the two reference mockups shown earlier. Uniformly calm and dark, highly readable under overlaid live glass cards. Absolutely no UI, panels, controls, knobs, text, letters, digits, labels, wordmark, keys, pads, buttons, arcs, highlights or focal objects. Flat straight-on texture, no folds, no scene, no vignette spotlight. Fine crafted floral and dot print, no claim of historical authenticity. Only the background artwork, full bleed.

### drum.png

Production asset drum.png for Czech Fanfrnoch instrument, square 1200x1200 target, with genuine transparent RGBA background and fully zero alpha surrounding the object. A single warm terracotta clay friction drum jug, small curved handle on right, rounded tapered handmade clay body decorated with restrained fine cream modrotisk floral sprigs and dot ornament as in the approved mockups. Its mouth is entirely covered with stretched parchment-like pig bladder, natural cream #DBC79F wrinkles and a gathered skirt securely tied with cord around neck. TWO visibly separate small tufts of dark horsehair emerge upward through the CENTRAL region of the skin: distinct tufts with a clear gap, natural stray fine strands. Three-quarter view slightly from above, see top skin ellipse and jug front. Entire object centered within generous 12 percent margins on all sides including hairs and handle. Polished realistic illustrative craft rendering matching mockups, warm terracotta #D88C5B and parchment #F6ECD8, subtle material lighting only. No floor, table, backdrop or scene. Clean antialiased transparent silhouette including fine hairs, no white fringe, no checkerboard drawn. No text, letters, digits, labels, logo, wordmark, UI, controls, knobs, keys, pads, buttons, arcs or added highlight graphics. Only the isolated drum.

### logo.png

Create logo.png, square 512x512 target with genuine transparent alpha background. A simple strong flat cream #F6ECD8 / parchment #DBC79F emblem silhouette of the Czech fanfrnoch friction drum: rounded clay jug with a small handle on the right, covered mouth with tied skin, TWO separate short upward horsehair tufts above the middle. Single compact bold iconic silhouette readable at 40 pt. Match the tiny cream jug beside the Fanfrnoch wordmark in the reference mockups, but include two clear hair tufts. Simplified solid shapes, handle has transparent negative-space hole, flat cream ink, only a minimal skin-rim line if needed. Centered, generous 15 percent clear margin. No text or wordmark of any kind, no letters digits labels, UI controls, circle enclosure, knobs, keys, pads, buttons, arcs, highlights, cast shadow, background or painted checkerboard. Only jug emblem on true transparent background.

### knob.png

Generate knob.png production raster asset, square target 512x512, actual transparent RGBA background. Exactly one blank circular audio knob cap, straight orthographic top-down view, mathematically centered, cap diameter 80 percent of canvas. Dark pearl graphite material with a very subtle warm pearl sheen and a fine concentric bevel ring. The entire cap, shading, bevel and soft shadow must be ROTATIONALLY SYMMETRIC: brightness depends ONLY on distance from the center, no directional lighting, no asymmetric reflections, no wedge, no spotlight, no top-side lighting. Soft concentric drop shadow contained inside transparent margins. Refined understated realistic material appropriate over midnight indigo #101D38 blue glass #233653 panels in Czech modrotisk instrument mockups. Absolutely NO pointer, notch, tick, marking, dot, line, value arc, color arc, text, number, letters, labels or added highlight graphic. No other controls, no background or painted checkerboard. Only the perfectly circular blank cap, true zero alpha outside.

### ornament.png

Production ornament.png decorative raster. True transparent RGBA background, cream #F6ECD8 modrotisk floral-and-dot print only. A VERY THIN horizontal ornamental divider band ultimately used at 2400 pixels wide by 64 pixels high. Generate a single slim horizontal line of small repeating eight-petal flowers alternating with tiny dotted diamond clusters and simple leafy sprigs, matching the small cream folk divider directly under header and above keyboard in Fanfrnoch reference mockups. Uniform delicate scale and spacing all the way across. Keep all pattern in a thin central horizontal band with large TRANSPARENT area above and below if canvas aspect ratio limits require; do not fill a wide rectangular image with multiple rows. Pattern must repeat seamlessly left-to-right; start and end in identical open transparent gaps halfway between repeated flowers. Flat cream ink, no directional shading, no background, no painted checkerboard, no border box, no text letters digits labels UI controls knobs pads keys buttons arcs highlights or other objects. The line consists only of botanical flowers leaves and dots; no lettering.

