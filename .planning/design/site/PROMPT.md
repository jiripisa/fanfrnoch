# Fanfrnoch — a website look

Fanfrnoch is a synthesized Czech friction drum for macOS 26: an app and an Audio Unit. The real
drum (a "fanfrnoch") is a terracotta clay jug covered with a tied parchment bladder, two tufts of
dark horsehair through the centre of the skin, pulled by wet hands; Czech carollers play it at
Christmas. Its window wears the "Modrotisk" look: see `reference/concept-1-keyboard.png`,
`reference/concept-1-pads.png` (the approved mockups), `reference/app-keyboard.png` and
`reference/app-pads.png` (screenshots of the real app), the panel's artwork in `reference/`
(`background.png` the indigo cloth, `drum.png` the jug, `logo.png`, `knob.png`, `ornament.png`
the cream floral band) and the app icon `reference/AppIcon.png`.

Palette: midnight indigo `#101D38` (ground), blue glass `#233653` (cards), cream `#F6ECD8`
(headings, names), terracotta `#D88C5B` (the accent: value arcs, chosen segment, selected pad),
parchment `#DBC79F` (values, captions). Mood: indigo *modrotisk* (Czech blueprint-dyed cloth) with
fine cream floral and dot ornament, and warm clay at its centre. Ornament is a craft-inspired
interpretation, not a reproduction of a documented textile.

Work only in the current directory. Do not stop to ask; make choices and write them down.

## The website: `docs/`

`docs/` is a copy of the project's GitHub Pages site: an overview (`index.html`), a manual
(`manual.html`) and the same two in Czech (`cs/`), styled by `assets/site.css` and
`assets/manual.css`. The texts of the pages are final. The styles are still those of a sibling
app (Brumle, a jaw harp, "Polar Khomus": midnight, silver and aurora cyan, a diamond ornament in
`assets/ornament.png`); `reference/brumle-site-DESIGN.md` describes that look, as a model of the
kind of work wanted, not of its colours. Restyle the site for Fanfrnoch:

1. Design a look for the site from the app: dark indigo ground, cream headings, parchment/cream
   body text, terracotta for links and buttons (check the contrast of text on the button and of
   links on indigo; a lighter terracotta tint for link text is fine), a serif display face for
   headings as in the app (`"New York", ui-serif, Georgia, serif`), SF/system sans for body.
   The two sites are siblings: same structure and tone, a look of its own.
2. Make graphics for it with your image tool, saved in `docs/assets/`:
   - a **hero illustration** `assets/hero-fanfrnoch.jpg` (the pages already point at this name):
     wide, e.g. 2400 × 1000, dark indigo modrotisk cloth, the terracotta fanfrnoch with its tied
     skin and two horsehair tufts (match `reference/drum.png` and the icon: exactly two tufts,
     coming out of the skin's centre), soft warm light, leaving calm space for the heading, the
     lede and the download button (the current layout puts the copy on the left over the art on
     wide screens and the art above the copy on narrow ones; keep or improve that);
   - a **tileable ornament band** or divider for section breaks, replacing `assets/ornament.png`
     (which is the sibling's diamond band): adapt `reference/ornament.png`, the app's own cream
     floral-and-dot band, so the site and the window match;
   - optionally a subtle full-page background texture (must stay quiet behind text).
   Keep each image under ~600 KB (JPEG for painted art, PNG only where alpha is needed); no text
   baked into images. Remove images you made and do not use.
3. Apply it: edit `assets/site.css` (and `assets/manual.css` only as needed so the manual
   matches — keep its `.fig`, `.view`, `.mark` figure system working and its marks positioned
   over the right controls), and the HTML of `index.html` and `cs/index.html` only where the look
   needs it (and the manuals only if truly needed). **Every change to an English page goes to its
   Czech twin too, tag for tag**; do not change any wording. Keep every link, download URL and
   version string exactly as they are (version 1.0.0,
   `https://github.com/jiripisa/fanfrnoch/releases/download/v1.0.0/Fanfrnoch-1.0.0.dmg`). Keep
   `assets/icon.png` (the app icon as macOS shows it, already final) and
   `assets/fanfrnoch-window.png` (the real app, already final) as they are. Keep it fast: no web
   fonts from third parties, no JS frameworks, no page JavaScript. The first line comment of
   each CSS file must name the Fanfrnoch look, not the sibling's.
4. It must read well at 1440 px and at 400 px wide (no horizontal page scroll), and respect
   `prefers-reduced-motion` if you animate anything (prefer not to).
5. Check your result yourself: render the pages with headless Chrome
   (`/Applications/Google Chrome.app/Contents/MacOS/Google Chrome --headless --screenshot=…
   --window-size=1440,2400 file://…`; use a `--user-data-dir` inside this directory and remove
   it afterwards), look at the screenshots, fix what is off. Save the screenshots in `shots/`.

## Deliverables

- the edited `docs/` with the new images
- `shots/*.png`: overview EN at 1440 and 400 wide, CS overview at 1440 and 400, manual EN at
  1440 (and one zoomed figure of the manual, to show its marks still sit on their controls)
- `DESIGN.md`: the look in a few lines (palette roles, type, graphics, what changed in which
  file), your choices, how you made and checked the images, and anything you could not do.

Your image tool's staging under `$CODEX_HOME/generated_images/` is fine; copy finals here.
Write nothing else outside this directory.
