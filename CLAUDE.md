# Fanfrnoch — project notes for Claude

A playable synthesized friction drum, after the Czech fanfrnoch: wet-hand strokes on a horsehair drum, its relatives from the Brummtopf to the cuíca, as an Audio Unit and a standalone app.

## Code

- Native macOS app, SwiftUI, macOS 26+. Swift Package Manager plus shell
  scripts; there is no Xcode project, so never add one.
- `Sources/FanfrnochCore` holds logic without UI (no SwiftUI/AppKit) and is
  covered by `swift test` (Swift Testing). `Sources/Fanfrnoch` is the SwiftUI
  app and stays a thin layer over the core. New logic goes into the core,
  test first.
- Build and run: `./run.sh` (debug, logs in the terminal), `./run.sh release`,
  `./build.sh [debug|release|dist|clean]`. Details in `development_workflow.md`.
- Every user-visible change gets a line under `## Unreleased` in
  `CHANGELOG.md`; the release notes and the update dialog come from it.
- **The Audio Unit's identity is permanent.** Its codes (`aumu` / `Fanf` /
  `JPis`, bundle id `io.jp4.fanfrnoch.audiounit`, the factory function
  `FanfrnochAUFactory`, the view class `FanfrnochAUViewFactory`) and its
  parameter IDs (the engine's parameter index, 0…80) never change: host
  projects find the plug-in and their automation by them. The parameter
  table only grows at its end. Validate every change of the Audio Unit with
  `auval` (`development_workflow.md` §2.1).

## Releases

- Use the project skill `release` (`.claude/skills/release/SKILL.md`) for
  every release; it holds the whole procedure and its checks.
- Signing: Developer ID Application certificate and the `notary`
  notarytool profile live in the login Keychain.
- The Sparkle EdDSA private key lives only in the login Keychain. Never put
  it (or an exported copy) into the repo; `Info.plist` holds only the public
  key (`SUPublicEDKey`).

## Website (`docs/`, GitHub Pages)

- Served from `main` / `docs` at https://jiripisa.github.io/fanfrnoch/. The download links and
  version strings on the pages are bumped with every release.
- `docs/manual.html` describes every control of the app. A user-visible
  change is not done until the manual says how to use it; screenshots live
  in `docs/assets/manual/`.
- **The site is bilingual.** Every change to `docs/index.html` or
  `docs/manual.html` must also go into `docs/cs/` (and the other way
  round). Shared styles live in `docs/assets/`.

## Planning

- Work runs in phases: `.planning/phases/NN-slug/` with `PLAN.md` and
  `VERIFICATION.md`, one feature branch per phase, merged to `main` with
  `--no-ff`; `ROADMAP.md` and `STATE.md` are updated at the end of each
  phase. See `development_workflow.md` §4.
