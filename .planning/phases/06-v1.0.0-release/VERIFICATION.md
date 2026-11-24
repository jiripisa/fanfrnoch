# Phase 06 — v1.0.0 release: verification (2026-11-24)

Local part (done before any push):
- Version 1.0.0 in `Resources/Info.plist` (both strings); CHANGELOG `## 1.0.0 — 2026-11-24`; the
  website already linked `v1.0.0/Fanfrnoch-1.0.0.dmg`. Version 1.0.0 as the first release: the
  design's call (spec §11), since it carries Brumle 1.0's feature set, icon and website.
- `swift test`: 290 tests in 33 suites passed.
- `./build.sh dist`: notarization `status: Accepted` for the app and the DMG, both stapled, `Done!`.
- `spctl -a -vv build/release/Fanfrnoch.app` and the DMG: `accepted`, `source=Notarized Developer ID`.
- `docs/appcast.xml`: version 1.0.0, the GitHub Release URL, a new `sparkle:edSignature`.
- `auval -v aumu Fanf JPis` on the distributed component: AU VALIDATION SUCCEEDED (the copied
  component removed again).

Publishing (repo, tag, GitHub Release, `main`, Pages, catalog): only after the author's OK.
