# Phase 03 — Verification (2026-11-23)

- Sizes and alpha read with `sips`: background 2200 × 1375 opaque; drum 1200 × 1200, logo,
  knob 512 × 512 and ornament 2400 × 64 with alpha.
- Codex's composite (assets on the background in the mockup's layout) was looked at: calm dark
  cloth, no fringes visible at panel size, the cap symmetric, the ornament without a seam.
- Code: `Artwork.khomus` → `Artwork.drum`, `KhomusView` → `DrumView`; `swift build` complete.

Not verified: the horsehair tufts have faint light fringes on a black preview (invisible on the
indigo cloth at panel size); the real Liquid Glass over the cloth, and the drum's crop in the
footer (DrumView still crops a lying harp's 2.6 : 1 box) — phase 04 lays out the panel.
