# App icon for "Fanfrnoch" (macOS 26)

Use your image generation tool to create the app icon artwork, then save it as `AppIcon.png`
in the current working directory.

Fanfrnoch is a synthesized Czech friction drum (a terracotta clay jug covered with a tied
parchment bladder, two tufts of dark horsehair through the centre of the skin) for macOS 26.
Its panel look is "Modrotisk": deep indigo blueprint-dyed cloth with fine cream floral and dot
ornament, a warm terracotta jug, cream and terracotta accents. References in `reference/`:
`drum.png` (the panel's drum illustration), `background.png` (the panel's cloth),
`concept-1-keyboard.png` (the whole panel).

## Requirements

- **1024 × 1024, fully opaque, full-bleed square artwork.** Do NOT draw the macOS rounded
  tile, a squircle, a frame, a drop shadow around the tile, or transparent corners: macOS 26
  applies its own mask to the full square. The art must fill every pixel to the edges.
- Subject: the fanfrnoch jug with its two horsehair tufts, large and centred (about 70 % of
  the height, kept well inside the central ~80 % so the system mask never clips it), on deep
  indigo modrotisk cloth with a sparse cream floral/dot pattern toward the edges.
- Bold, simple, readable at 32 px: strong silhouette, warm terracotta against indigo, soft
  light, little fine detail. No text, letters or digits.
- Save as `AppIcon.png` (sRGB, no alpha channel). Check with `sips -g pixelWidth -g pixelHeight
  -g hasAlpha AppIcon.png` (1024, 1024, no). Also save `preview-32.png` and `preview-128.png`
  (downscaled with `sips -Z`) and look at them.
- Write `icon.md` with the generation prompt and your checks.

Your image tool's automatic staging under `$CODEX_HOME/generated_images/` is fine: copy the
final PNG from there into the current directory. Apart from that, write nothing outside the
current working directory. Do not stop to ask questions.
