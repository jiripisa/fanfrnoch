# Phase 05 — App icon and website look: Plan

**Goal:** Fanfrnoch's own app icon, built so that macOS 26 shows it filling the icon shape, and a
website that tells what Fanfrnoch is and wears the Modrotisk look, with graphics by Codex and a
picture of the real app.

**Spec:** `.planning/specs/2026-11-23-instrument-design.md` §1, §10. Palette and type: concept 1
"Modrotisk" (`.planning/design/concepts/concepts.md`). Pattern: Brumle's phase 07
(`../Brumle/.planning/phases/07-icon-website/`, `../Brumle/.planning/design/site/`) and, for the
icon pipeline, DevPulse's `build.sh` and `Resources/AppIcon.icon`.

**Branch:** `feature/05-icon-website` from `main`; merged back with `--no-ff` at the end of the
phase (not by this plan's builder). Never pushed.

## Global constraints

- The Audio Unit's identity and the parameter table do not change (CLAUDE.md).
- The site is bilingual: `docs/index.html` and `docs/cs/index.html` keep the same tags in the
  same order; so do the two manuals.
- Facts on the site come from the manual, the CHANGELOG and the code, not from the brief.
- The app is launched by its path, never by its name; its window is captured by the window id
  of the process that was launched (`CGWindowListCopyWindowInfo`, `kCGWindowOwnerPID`), never
  the screen; the app is not brought to the front. Scratch work lives in the session's
  scratchpad and leaves nothing behind.
- Conventional Commits with a scope, no AI attribution; `git status` before every commit.

## Tasks

1. **App icon through actool.** `Resources/AppIcon.png` becomes Codex's approved art (1024 px,
   opaque, full bleed); Codex's prompt and notes go to `.planning/design/icon/`.
   `Resources/AppIcon.icon` is an Icon Composer document (one layer, no glass, shadow,
   translucency or specular; an indigo fill) holding no image in the repo. `build.sh` (every
   mode, so `release` and `dist`) copies it to a temporary folder with the master as
   `Assets/AppIcon.png` and compiles it with `xcrun actool` into `Contents/Resources/Assets.car`
   plus a fallback `AppIcon.icns`, instead of `sips` + `iconutil`. `Info.plist` gets
   `CFBundleIconName`. Without Xcode the build stops with a hint. `development_workflow.md` and
   `README.md` say Xcode is needed.
2. **Check the icon** in the built bundle: `Assets.car` and `AppIcon.icns` present,
   `CFBundleIconName` = `AppIcon`; the icon macOS shows for `build/release/Fanfrnoch.app`,
   rendered through `NSWorkspace.shared.icon(forFile:)` by a scratch Swift script into a PNG,
   fills the shape with no light tile or frame.
3. **Website texts** (`docs/index.html`, `docs/cs/index.html`, tag for tag): what Fanfrnoch is
   and its relatives as programs, what sets it apart (synthesized, not sampled; strokes that
   scoop, drift and jump; two hands; a group of pads is one drum), the features (keyboard and
   pad modes, sixteen pads with groups, Send to pad, presets, kits, MIDI learn, LFO and VEL
   amounts, Audio Unit, updates), macOS 26, download 1.0.0, the manual. Brumle's tone: plain,
   short, no hype.
4. **Website look by Codex.** A scratch folder with a copy of `docs/`, references (concept
   mockups, the panel art, the icon, the manual's pictures of the real app) and a `PROMPT.md`
   after Brumle's Part 2: a hero illustration, a tileable ornament band, maybe a quiet texture,
   `site.css` (and `manual.css` only as needed) in the Modrotisk palette, screenshots, a
   `DESIGN.md`. Codex's result is reviewed in our own headless-Chrome renders and fixed where
   needed, then brought back; `PROMPT.md` and `DESIGN.md` go to `.planning/design/site/`. The
   site's icon (`docs/assets/icon.png`, 256 px) comes from the new art.
5. **The app's window on the site:** `docs/assets/fanfrnoch-window.png` from `./build.sh release`,
   captured as above, then the app quit and its preferences, Application Support, caches and
   HTTP storage removed.
6. **Leftovers:** no Brumle, jaw harp, khomus or Polar Khomus in `docs/` (CSS comments too);
   Brumle's images the site no longer uses are removed.
7. **Close:** `swift test`, `./build.sh release`, CHANGELOG line, `VERIFICATION.md`,
   `ROADMAP.md`, `STATE.md`.

## Acceptance

- The built app's icon fills the macOS icon shape, no light frame, seen in an `NSWorkspace`
  rendering; `Assets.car` and `CFBundleIconName` in the bundle; release and dist build it the
  same way.
- Both overview pages describe Fanfrnoch truthfully, with the same tags; links, the download URL
  and the version 1.0.0 are right; they read well at 1440 and 400 px in headless Chrome; the
  manual's figures still work.
- `swift test` green, `./build.sh release` OK, no leftovers of the jaw harp in `docs/`.
