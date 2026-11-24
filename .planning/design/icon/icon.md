# Fanfrnoch app icon

Created with the built-in image generation tool. Inspected all three supplied references before generation: `reference/drum.png`, `reference/background.png`, and `reference/concept-1-keyboard.png`.

## Generation prompt

Use case: stylized-concept.
Create final app icon artwork for Fanfrnoch, a synthesized Czech friction drum, as a 1024 x 1024 fully opaque full-bleed square image.
Visual guidance from inspected reference images: a warm orange terracotta jug, rounded generous body tapering to a narrow flat foot, one loop handle on the right; a cream parchment bladder stretched over the broad mouth, softly gathered below the rim and secured by a simple cream cord tied at the right front; exactly TWO separate dark brown horsehair tufts emerging side by side through the centre of the skin, fanning gently left and right. Restrained cream folk-floral decoration on the front of the clay jug. Deep indigo Modrotisk dyed cloth background with sparse fine cream floral sprigs and a few dots toward the outer edges.
Composition: large centered complete jug including both horsehair tufts, occupying about 70 percent of image height from upper hair tip to base. All of the subject and handle safely within central 80 percent of canvas. Clear separation between the two tufts. Slight view from above to show the cream drum skin. Bold simple readable silhouette at 32 px; simplify hair into two substantial tapered tufts, simplify folds and decoration. Warm terracotta against deep indigo. Soft light, softly modeled illustrative ceramic form, restrained cloth texture and little fine detail. Background continuous all the way to every edge and all four corners.
STRICT: this is raw square artwork, NOT a rendering of an app tile. No rounded rectangle, no squircle, no frame, no inset panel, no border, no tile drop shadow, no transparent corners. No text, no letters, no digits, no logo, no watermark, no UI, no keyboard. Full bleed opaque indigo cloth covers every pixel. Deliver one square PNG image, 1024 x 1024, sRGB.

## Composition refinement prompt

The first result was too large within the square. The following edit added mask clearance:

Edit this artwork with only one composition change: reduce the entire jug AND both horsehair tufts together to 82 percent of their current size, centered on the canvas, extending the surrounding indigo cloth naturally behind the reduced subject. The entire subject from the top hair tips to the foot must occupy about 70 percent of canvas height (roughly y=154 to y=870 on a 1024 pixel square); keep the handle inside the central 80 percent of the canvas too. Preserve the same jug, exactly two separate hair tufts, colors, cream ornaments, material rendering, soft lighting, sparse corner floral sprigs and dots. FULL BLEED opaque square indigo cloth to every edge and corner. No rounded tile, no frame, no text. Output 1024 x 1024 sRGB PNG.

## Export and checks

Copied the final generated PNG into this directory as `AppIcon.png`. Used native `sips` to resize to 1024 × 1024 and convert to the system sRGB profile, then created the previews with `sips -Z 32` and `sips -Z 128`.

Verification command:

```sh
sips -g pixelWidth -g pixelHeight -g hasAlpha -g profile AppIcon.png preview-32.png preview-128.png
```

| File | Width | Height | Alpha | Profile |
| --- | ---: | ---: | --- | --- |
| AppIcon.png | 1024 | 1024 | no | sRGB IEC61966-2.1 |
| preview-32.png | 32 | 32 | no | sRGB IEC61966-2.1 |
| preview-128.png | 128 | 128 | no | sRGB IEC61966-2.1 |

Visually inspected the generated artwork and both saved previews. Full-bleed indigo cloth reaches every edge and corner, without a rounded tile, frame, or tile drop shadow. The complete terracotta jug, right loop handle, cream tied skin, and two distinct horsehair tufts sit comfortably inside the central 80 percent; the subject occupies approximately two-thirds of the height, close to the requested 70 percent. Sparse cream floral sprigs and dots remain toward the edges. No text, letters, or digits appear. At 128 px, both tufts and the tied skin are clear. At 32 px, the warm jug and cream skin retain a strong silhouette, with the tufts visible as two small arcs; fine floral details naturally merge at this size.

