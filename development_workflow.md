# Fanfrnoch — Development Workflow, Build & Distribution

## 1. Toolchain & Project Layout

- Xcode command line tools (Swift 6.2), macOS 26+. No Xcode project: Swift
  Package Manager builds the code, `build.sh` assembles the `.app` bundle.

```
fanfrnoch/
├── Package.swift
├── Sources/Fanfrnoch/          # SwiftUI app (thin layer)
├── Sources/FanfrnochCore/      # logic without UI, tested
├── Sources/FanfrnochDSP/       # the sound engine, C++ behind a C interface
├── Sources/FanfrnochUI/        # the instrument's panel, shared by the app and the plug-in
├── Sources/FanfrnochAU/        # the Audio Unit (AUv2 instrument), C++ on ThirdParty/AudioUnitSDK
├── Sources/FanfrnochAUView/    # the Audio Unit's window in a host
├── Sources/FanfrnochAUExports/ # no code: what the Audio Unit's library exports (Package.swift)
├── Tests/FanfrnochCoreTests/   # Swift Testing
├── Resources/               # Info.plist, entitlements, AppIcon.png (1024 px)
├── scripts/make_appcast.py  # Sparkle feed, called by build.sh dist
├── docs/                    # GitHub Pages website + manual
├── build.sh                 # debug | release | dist | clean
└── run.sh                   # debug (logs in terminal) | release (open .app)
```

## 2. Build (`build.sh`)

| Command | Result |
|---|---|
| `./build.sh` / `./build.sh debug` | `swift build` → `build/debug/Fanfrnoch.app` (ad-hoc signed) |
| `./build.sh release` | same with `-c release` → `build/release/Fanfrnoch.app` |
| `./build.sh dist` | release build → **Developer ID signing (hardened runtime)** → notarized + stapled app → **DMG** → notarized + stapled DMG → `docs/appcast.xml` |
| `./build.sh clean` | removes `build/` and `.build/` |

### 2.1 App-bundle assembly (all modes)

Executable → `Contents/MacOS`, `Resources/Info.plist` → `Contents/`,
`Resources/AppIcon.png` → `AppIcon.icns` (sips + iconutil), Sparkle.framework →
`Contents/Frameworks` (XPC services removed; the app is unsandboxed), PkgInfo,
then an ad-hoc signature with the entitlements; a signature that fails stops
the build. New resource files must be copied in `build.sh` explicitly.
`Resources/Art/` (the panel's artwork) goes to `Contents/Resources/Art`.

**The Audio Unit** is assembled in the same step: `libFanfrnochAU.dylib` →
`Contents/PlugIns/Fanfrnoch.component/Contents/MacOS/Fanfrnoch`, with
`Resources/AudioUnit-Info.plist` as its `Info.plist`. The dylib exports only
the factory function `FanfrnochAUFactory` (`Package.swift`), because a plug-in
shares the host's process with other plug-ins. `Resources/Art/` is copied
into the component too: its own window (the class `FanfrnochAUViewFactory`,
which the host finds through the unit's CocoaUI property) shows the app's
panel. `build.sh` writes the app's version into that plist (both strings and
the numeric `AudioComponents` version, `major << 16 | minor << 8 | patch`),
so the version is bumped in one place. The component is signed before the
app (ad-hoc, or Developer ID + hardened runtime in `dist`). Users install it
from the app: Settings › Install Audio Unit copies it to
`~/Library/Audio/Plug-Ins/Components`.

Check a build of the plug-in with Apple's validator:

```
cp -R build/release/Fanfrnoch.app/Contents/PlugIns/Fanfrnoch.component ~/Library/Audio/Plug-Ins/Components/
auval -v aumu Fanf JPis        # must end with AU VALIDATION SUCCEEDED
```

### 2.2 Distribution (`dist`)

1. Sign Sparkle's parts inside-out, then the Audio Unit's component, then the
   app with the first "Developer ID Application" identity in the Keychain,
   hardened runtime, timestamp.
2. Notarize the zipped app (`notarytool --keychain-profile notary --wait`), staple it.
3. Build `build/Fanfrnoch.dmg` (app + Applications symlink), sign, notarize, staple.
4. `scripts/make_appcast.py` signs the stapled DMG with Sparkle's `sign_update`
   (EdDSA private key from the login Keychain) and writes `docs/appcast.xml`:
   version, release notes from the CHANGELOG section, the GitHub Release
   download URL, length and signature. Create the GitHub Release (DMG uploaded
   as `Fanfrnoch-<version>.dmg`) **before** pushing the appcast, so the feed
   never points at a missing file.

A notarization `HTTP status code: 403. A required agreement is missing or has
expired` is an account issue: accept the updated agreement at
developer.apple.com/account.

### 2.3 One-time signing setup (per machine)

1. A **Developer ID Application** certificate in the login keychain.
2. A stored notarization profile named `notary` (or set `NOTARY_PROFILE`):
   ```
   xcrun notarytool store-credentials notary \
     --apple-id <apple-id-email> --team-id <TEAMID> --password <app-specific-password>
   ```
3. The Sparkle EdDSA key: `.build/artifacts/sparkle/Sparkle/bin/generate_keys`
   keeps the private key in the login Keychain and prints the public key that
   lives in `Info.plist` (`SUPublicEDKey`). Back it up
   (`generate_keys -x <file>`, kept offline): without it no update can ever be
   signed for existing installs again.

### 2.4 Entitlements & sandbox policy

The app ships **unsandboxed** (`com.apple.security.app-sandbox = false`),
which is fine for Developer ID / DMG distribution; Gatekeeper needs the
hardened runtime and notarization. Add entitlements to
`Resources/Fanfrnoch.entitlements` only when a feature needs them.

## 3. Run (`run.sh`)

- `./run.sh debug` *(default)* — rebuilds when anything under `Sources/` or
  `Resources/` is newer than the binary, registers the bundle with Launch
  Services, then runs the binary in the terminal: logs stream live, Ctrl+C quits.
- `./run.sh release` — rebuilds if stale, then `open`s the app.

## 4. Development Methodology

- Logic goes into `FanfrnochCore`, test first (`swift test`); the UI is checked
  by running the app.
- Conventional Commits with a scope: `feat(core): …`, `fix(ui): …`,
  `docs(manual): …`, `chore(release): v1.2.0 — …`.
- `main` is always green: builds, tests pass, the app launches.

### Phases

- `.planning/ROADMAP.md` lists phases (newest first) with status;
  `.planning/STATE.md` says where work stands and what comes next.
- One phase = `.planning/phases/NN-slug/` (`PLAN.md`, `VERIFICATION.md`) =
  one branch `feature/NN-slug` = one `--no-ff` merge into `main`.
- Definition of done: acceptance criteria checked, `swift test` green, app
  built and run, CHANGELOG and manual updated, ROADMAP/STATE updated.

### Versioning & releases

- The version lives in `Resources/Info.plist` (`CFBundleShortVersionString`
  and `CFBundleVersion`), semantic versioning, starting at 0.1.0.
- Releases follow the project skill `.claude/skills/release/SKILL.md`.
- Pushes to GitHub happen only after explicit confirmation.
