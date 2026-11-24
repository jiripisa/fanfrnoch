# Fanfrnoch — Indigo Modrotisk

Midnight indigo `#101D38` is the ground, blue glass `#233653` the supporting surface, cream `#F6ECD8` the headings, warm cream `#E5D8BE` the body, and parchment `#DBC79F` the captions. Terracotta `#D88C5B` carries buttons; the lighter `#E8A577` carries links and manual annotations. System serif (`"New York", ui-serif, Georgia, serif`) echoes the app's lettering; SF/system sans keeps the prose readable.

The jug is the focal point: a warm, tactile instrument against indigo cloth, with exactly two horsehair tufts emerging near the skin's centre. Desktop copy sits to its left; on narrow screens the illustration comes first, above the copy. Fine cream floral-and-dot dividers connect the website to the app. The ornament is a craft-inspired interpretation, not a reproduction of a documented textile. Open feature columns preserve the sibling site's structure and tone. Texture stays in the hero so long text remains quiet. No animation, remote fonts, frameworks, or page JavaScript.

## Files and choices

- `docs/assets/site.css`: shared Fanfrnoch palette, terracotta buttons, cream typography, floral dividers, wider desktop copy, and corrected mobile artwork order. Existing HTML was sufficient; all four pages are unchanged, including every word, link, download URL and version.
- `docs/assets/manual.css`: comments now name the Fanfrnoch look. The manual inherits the palette; every `.fig`, `.view`, and `.mark` geometry rule remains unchanged.
- `docs/assets/hero-fanfrnoch.jpg`: generated still life, 1920 × 819, 297,711 bytes. The image tool returned this resolution rather than the requested approximate 2400 × 1000; its native resolution exceeds the rendered desktop width, so no upscaling was needed.
- `docs/assets/ornament.png`: generated adaptation of the supplied app ornament, transparent 1374 × 90, 102,893 bytes. Used as a centred, non-repeating divider; this avoids claiming that the generated endpoints form a perfect seamless tile.
- `docs/assets/icon.png`, `docs/assets/fanfrnoch-window.png`, and every manual screenshot are unchanged.
- `tools/render-site.cjs`: repeatable headless Chrome capture and checks using an existing Playwright installation. No dependencies were installed. There was no project renderer; the small helper adds DOM overflow/image checks and figure capture that a plain screenshot command cannot supply.
- `shots/`: full EN/CS overviews at 1440 and 400, EN/CS manual opening views at both widths, a zoomed manual figure, browser results, and original-file checksum evidence.

## Image production

Both graphics were made with the built-in image tool, using the supplied local reference images. The hero used `drum.png`, `AppIcon.png`, and `background.png`; the divider used `ornament.png`. The prompts are recorded in `tools/image-prompts.md`. Generated originals remain in the tool's permitted staging directory. Only the two used finals were copied into this project.

The system `sips` utility converted the hero to JPEG at quality 78. The generated ornament had excessive transparent padding; a centred 90 × 1374 crop removed that padding while retaining alpha. Both finals were visually inspected, including the two tufts, clear space for copy, ornament silhouette, and their appearance in the rendered pages. No one-off image processing script was needed.

## Verification

Headless `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` rendered all four pages at 1440 and 400 pixels. All eight checks reported zero horizontal page overflow, zero failed images, and zero scripts. Both manuals retain 11 figures and 48 marks. The zoomed Stroke figure shows the frames on Attack and Key Up. All requested screenshots and the additional manual views were visually reviewed.

WCAG relative-luminance contrast: button text 6.23:1; links on indigo 8.03:1; links on blue glass 5.85:1; body on indigo 11.87:1; captions on indigo 10.11:1. The original checksums confirm all four HTML pages and the protected graphics are byte-for-byte unchanged (`shasum -a 256 -c shots/preserved.sha256`). No animation needs reduced-motion handling.

Chrome initially aborted in the filesystem sandbox, then ran successfully with execution escalation. Its temporary user-data directory was inside this project and was removed after rendering. Visual review caught one full-page screenshot compositor artifact; capturing each overview in a single page-height viewport resolved it without changing the site.

To repeat the browser checks: `node tools/render-site.cjs /path/to/installed/playwright`. Results are in `shots/browser-checks.json`. Verification covers local Chrome rendering; no deployed-site or other-browser checks were performed. No requested deliverable remains blocked.

## Review by the builder (phase 05)

- The hero image is 1920 × 819, so both overview pages give it `width="1920" height="819"`
  (they said 2400 × 1000, the size the prompt asked for).
- The divider above Download sat on a box of the page's indigo over the lighter Download band;
  `#get::before` now lays the ornament on a background half indigo, half the band's colour.
- The image prompts are in `image-prompts.md` beside this file. Codex's render helper and its
  screenshots stay in the session's scratchpad.
