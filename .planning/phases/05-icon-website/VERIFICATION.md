# Phase 05 — Verification (2026-11-24)

Fanfrnoch has its own app icon, compiled with actool from an Icon Composer document, and the
website tells of the friction drum in English and Czech, in the Modrotisk look Codex made for it,
with a picture of the real app. Checks ran on `1a27a4f`.

| Check | Result |
|---|---|
| `swift test` | `✔ Test run with 290 tests in 33 suites passed after 16.597 seconds.` No `✘` or `warning:` line |
| `./build.sh release` | `Build complete: …/build/release/Fanfrnoch.app`, no `warning:` or `ERROR`; `Compiling app icon...` ran |
| `codesign --verify --deep --strict build/release/Fanfrnoch.app` | passes |
| The bundle's icon | `Contents/Resources/Assets.car` (4.9 MB) and the fallback `AppIcon.icns` (114 KB); `CFBundleIconName` = `AppIcon` (and `CFBundleIconFile` = `AppIcon`) |
| The icon macOS shows for `build/release/Fanfrnoch.app` | rendered through `NSWorkspace.shared.icon(forFile:)` by a scratch Swift script on a light and a dark ground (`icon-as-macos-shows-it.png`): the cloth and the jug fill the system's squircle edge to edge, no light tile or frame; representations 16…1024 px (2048 at 2×) |
| `Resources/AppIcon.png` | Codex's approved art, 1024 × 1024, no alpha (`sips`: `hasAlpha: no`) |
| `docs/assets/icon.png` | 256 px, the same `NSWorkspace` rendering on transparency, so it carries the system's mask |
| The app's window on the site | `docs/assets/fanfrnoch-window.png`: the release app started by its path (`…/Contents/MacOS/Fanfrnoch`), window id from `CGWindowListCopyWindowInfo` for the launched pid, `screencapture -x -o -l <id>`, not brought to the front; the title bar cut off and the corners laid on indigo as Brumle's picture, 64 levels per channel: 2200 × 1464, 884 KB, keyboard mode with the default sound |
| Clean-up after the app | quit by its pid; `defaults read io.jp4.fanfrnoch`: domain not found; no `~/Library/Preferences/io.jp4.fanfrnoch.plist`, `Application Support/Fanfrnoch`, `Caches/io.jp4.fanfrnoch`, `HTTPStorages/io.jp4.fanfrnoch`; the scratch Swift scripts wrote no preferences |
| Website in headless Chrome (Playwright on the local Chrome, Codex's helper, run again on the final pages) | EN and CS overview and manual at 1440 and 400 px: page width = viewport (no horizontal scroll), no failed image, no script; both manuals 11 figures and 48 marks. Looked at: EN 1440, EN 400, CS 1440, CS 400, manual EN 1440 (marks on Program, Preset, the mode, …) |
| EN and CS overview | the same tags in the same order (language attributes, links, sources and texts aside); both download buttons point at `…/releases/download/v1.0.0/Fanfrnoch-1.0.0.dmg`; "Version 1.0.0" / "Verze 1.0.0", "Download version 1.0.0" / "Stáhnout verzi 1.0.0" |
| Manuals | HTML unchanged in this phase; `manual.css` changed only in its comments |
| Contrast (Codex's check) | button text 6.23 : 1, links on indigo 8.03 : 1, on blue glass 5.85 : 1, body 11.87 : 1, captions 10.11 : 1 |
| Images | hero JPEG 1920 × 819, 298 KB; ornament PNG 1374 × 90, 103 KB; every image in `docs/assets/` is used by a page or a stylesheet |
| Leftovers | `grep -rniE "brumle|jaw ?harp|khomus|polar" docs`: no match (also none in the CSS comments). `hero-khomus.jpg` removed; Brumle's diamond `ornament.png` replaced |

## Decisions [builder]

- **The Icon Composer document** is DevPulse's: one layer, glass, shadow, translucency and
  specular off, holding no image in the repo; its fill is the indigo `#101D38`. actool targets
  macOS 26 (`--minimum-deployment-target 26.0`). The step runs in every mode before anything is
  signed, so `dist` ships what `release` showed.
- **Xcode is needed now** to build (actool): `development_workflow.md` §1 and §2.1.1, `README.md`
  and both overview pages ("Build from source") say so.
- **Groups, not mute groups:** the brief asked for "16 pads with mute groups"; in Fanfrnoch the
  pads of a group are one drum (phase 04), and the pages say that.
- **No sibling link:** Brumle's overview has no links to its siblings, so neither has Fanfrnoch's.
  The template has no apple-touch icon either; the pages keep `<link rel="icon">` only.
- **Hero and window picture:** the hero image Codex's tool gave is 1920 × 819; the pages' `width`
  and `height` say so. The window picture is the content without the title bar, as Brumle's.
- **The divider above Download** sat on an indigo box over the lighter Download band; it now lies
  on a background half of each colour (`#get::before`).
- **CHANGELOG:** one line for the icon. The website is not part of the app, as in Brumle.

## Not verified

- `./build.sh dist` was not run (it signs with the Developer ID and notarizes; that is phase 06).
  It uses the same icon step as `release`, before signing.
- The icon was seen only through `NSWorkspace`'s rendering, not in the Dock or the Finder.
- The website in Safari and on a real phone; headless Chrome only. `--window-size=400` in plain
  headless Chrome lays the page out wider than 400 px, so the 400 px views come from Playwright's
  viewport.
- Sound: nothing was played in this phase (no engine change).
