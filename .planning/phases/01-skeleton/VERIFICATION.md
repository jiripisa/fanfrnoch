# Phase 01 — Verification (2026-11-23)

- Source: `git archive main` of `../Brumle` at 4b45a36 (v1.0.0), without its `.planning`.
- Renamed: every path and every text occurrence of Brumle/brumle/BRUMLE, the AU subtype
  `Brml` → `Fanf` and the tests' in-process subtype `Brmt` → `Fant`.
- Identity: `io.jp4.fanfrnoch`, `io.jp4.fanfrnoch.audiounit`, `FanfrnochAUFactory`,
  `FanfrnochAUViewFactory`, feed `https://jiripisa.github.io/fanfrnoch/appcast.xml`, the shared
  Sparkle public key.
- Version 0.1.0, CHANGELOG reset to Unreleased, appcast emptied.
- `swift build` complete; `swift test`: 275 tests in 33 suites passed.

Not yet Fanfrnoch: the engine (jaw harp), the panel's sections and art, the website and manual.
