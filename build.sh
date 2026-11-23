#!/bin/bash
# Build script for Fanfrnoch (development_workflow.md §2)
# Usage: ./build.sh [debug|release|dist|clean]
#
#   debug   — debug build, no optimization (default)
#   release — optimized build + app bundle
#   dist    — release build + Developer ID signing + notarization (app, then DMG) + stapled DMG
#   clean   — remove build artifacts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="Fanfrnoch"
BUILD_DIR="$SCRIPT_DIR/build"
SPM_BUILD_DIR="$SCRIPT_DIR/.build"
ICON_SOURCE="Resources/AppIcon.png"
ICON_DOCUMENT="Resources/AppIcon.icon"
NOTARY_PROFILE="${NOTARY_PROFILE:-notary}"
MODE="${1:-debug}"

# --- Clean ---
if [ "$MODE" == "clean" ]; then
    echo "Cleaning build artifacts..."
    rm -rf "$BUILD_DIR"
    rm -rf "$SPM_BUILD_DIR"
    echo "Clean complete."
    exit 0
fi

# --- Validate mode ---
if [[ "$MODE" != "debug" && "$MODE" != "release" && "$MODE" != "dist" ]]; then
    echo "Unknown mode: $MODE"
    echo "Usage: ./build.sh [debug|release|dist|clean]"
    exit 1
fi

# --- SPM Build ---
if [ "$MODE" == "debug" ]; then
    SPM_CONFIG="debug"
    APP_BUNDLE="$BUILD_DIR/debug/$APP_NAME.app"
    echo "Building $APP_NAME (debug)..."
else
    SPM_CONFIG="release"
    APP_BUNDLE="$BUILD_DIR/release/$APP_NAME.app"
    echo "Building $APP_NAME (release)..."
fi

swift build -c "$SPM_CONFIG"

# --- App Bundle ---
echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$SPM_BUILD_DIR/$SPM_CONFIG/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/"

# Window artwork (background, drum, logo, knob cap, ornament)
if [ -d "Resources/Art" ]; then
    cp -R "Resources/Art" "$APP_BUNDLE/Contents/Resources/Art"
fi

# --- Audio Unit ---
# The AUv2 plug-in ships inside the app (Contents/PlugIns); the app's settings
# window installs it into ~/Library/Audio/Plug-Ins/Components. Its version
# comes from the app's Info.plist: one place to bump.
COMPONENT="$APP_BUNDLE/Contents/PlugIns/$APP_NAME.component"
mkdir -p "$COMPONENT/Contents/MacOS"
cp "$SPM_BUILD_DIR/$SPM_CONFIG/lib${APP_NAME}AU.dylib" "$COMPONENT/Contents/MacOS/$APP_NAME"
cp "Resources/AudioUnit-Info.plist" "$COMPONENT/Contents/Info.plist"
echo -n "BNDL????" > "$COMPONENT/Contents/PkgInfo"
APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
IFS=. read -r V_MAJOR V_MINOR V_PATCH <<< "$APP_VERSION"
AU_VERSION=$(( (10#${V_MAJOR:-0} << 16) | (10#${V_MINOR:-0} << 8) | 10#${V_PATCH:-0} ))
/usr/libexec/PlistBuddy \
    -c "Set :CFBundleShortVersionString $APP_VERSION" \
    -c "Set :CFBundleVersion $APP_VERSION" \
    -c "Set :AudioComponents:0:version $AU_VERSION" \
    "$COMPONENT/Contents/Info.plist"

# The plug-in's own window shows the same artwork as the app's.
if [ -d "Resources/Art" ]; then
    mkdir -p "$COMPONENT/Contents/Resources"
    cp -R "Resources/Art" "$COMPONENT/Contents/Resources/Art"
fi

# Embed Sparkle (auto-update). The app is unsandboxed, so the XPC services
# (only needed by sandboxed apps) are left out.
SPARKLE_SRC=".build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"
SPARKLE_FW="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
mkdir -p "$APP_BUNDLE/Contents/Frameworks"
ditto "$SPARKLE_SRC" "$SPARKLE_FW"
rm -rf "$SPARKLE_FW/Versions/B/XPCServices" "$SPARKLE_FW/XPCServices"

# codesign --force without its "replacing existing signature" lines. A failed
# signature stops the build and shows what codesign said.
sign() {
    local output
    if ! output=$(codesign --force "$@" 2>&1); then
        echo "$output" >&2
        echo "ERROR: codesign failed (codesign --force $*)" >&2
        return 1
    fi
    printf '%s' "$output" | grep -v "replacing existing signature" || true
}

# Sign Sparkle's pieces inside-out, then the framework (identity "-" = ad-hoc).
sign_sparkle() {
    local identity="$1"; shift
    for item in "$SPARKLE_FW/Versions/B/Autoupdate" \
                "$SPARKLE_FW/Versions/B/Updater.app" \
                "$SPARKLE_FW"; do
        sign "$@" --sign "$identity" "$item"
    done
}

# Compile the app icon into Assets.car, plus a fallback AppIcon.icns. macOS masks an
# Icon Composer document to its own shape; a plain .icns that does not fill the shape
# sits small on a light tile. The document holds no image in the repo: the full-bleed
# master Resources/AppIcon.png goes into a temporary copy (actool does not follow a
# symlink there). actool comes with Xcode, not with the Command Line Tools.
echo "Compiling app icon..."
ICON_DIR=$(mktemp -d)
# Removed however the script ends, also when actool fails (build.sh sets no other trap).
trap 'rm -rf "$ICON_DIR"' EXIT
ditto "$ICON_DOCUMENT" "$ICON_DIR/AppIcon.icon"
mkdir -p "$ICON_DIR/AppIcon.icon/Assets"
cp "$ICON_SOURCE" "$ICON_DIR/AppIcon.icon/Assets/AppIcon.png"
mkdir -p "$ICON_DIR/out"
if ! ACTOOL_LOG=$(xcrun actool "$ICON_DIR/AppIcon.icon" \
    --compile "$ICON_DIR/out" \
    --output-format human-readable-text --notices --warnings --errors \
    --output-partial-info-plist "$ICON_DIR/partial.plist" \
    --app-icon AppIcon --include-all-app-icons --enable-on-demand-resources NO \
    --development-region en --target-device mac --minimum-deployment-target 26.0 \
    --platform macosx 2>&1); then
    echo "$ACTOOL_LOG"
    if echo "$ACTOOL_LOG" | grep -qiE "command line tools|requires Xcode|unable to find utility"; then
        echo "ERROR: compiling the app icon needs Xcode, and only the Command Line Tools are selected."
        echo "Install Xcode, then run: sudo xcode-select -s /Applications/Xcode.app"
    else
        echo "ERROR: actool could not compile $ICON_DOCUMENT."
    fi
    exit 1
fi
if [ ! -f "$ICON_DIR/out/Assets.car" ] || [ ! -f "$ICON_DIR/out/AppIcon.icns" ]; then
    echo "$ACTOOL_LOG"
    echo "ERROR: actool did not write Assets.car and AppIcon.icns."
    exit 1
fi
cp "$ICON_DIR/out/Assets.car" "$ICON_DIR/out/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
rm -rf "$ICON_DIR"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Strip extended attributes
xattr -cr "$APP_BUNDLE"

# Ad-hoc sign with entitlements for debug/release (TCC needs entitlements
# baked into the binary signature, not just present in the bundle).
# Inside-out: Sparkle and the Audio Unit before the app that holds them.
sign_sparkle -
sign --sign - "$COMPONENT"
sign --sign - --entitlements "Resources/$APP_NAME.entitlements" "$APP_BUNDLE"

echo "Build complete: $APP_BUNDLE"

# --- Stop here unless dist ---
if [ "$MODE" != "dist" ]; then
    echo "To run: ./run.sh $SPM_CONFIG"
    exit 0
fi

# --- Code Signing ---
IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')

if [ -z "$IDENTITY" ]; then
    echo "ERROR: No 'Developer ID Application' identity found in Keychain; cannot build dist."
    exit 1
fi

echo "Signing with: $IDENTITY"

sign_sparkle "$IDENTITY" --options runtime --timestamp
codesign --force --options runtime --timestamp --sign "$IDENTITY" "$COMPONENT"
codesign --force --options runtime --timestamp \
    --entitlements "Resources/$APP_NAME.entitlements" \
    --sign "$IDENTITY" \
    "$APP_BUNDLE"

echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

# --- Notarize and staple the app itself (so the copied app works offline) ---
APP_ZIP="$BUILD_DIR/$APP_NAME-notarize.zip"
rm -f "$APP_ZIP"
ditto -c -k --keepParent "$APP_BUNDLE" "$APP_ZIP"
echo "Submitting $APP_NAME.app for notarization (this may take a few minutes)..."
xcrun notarytool submit "$APP_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
rm -f "$APP_ZIP"
echo "Stapling notarization ticket to $APP_NAME.app..."
xcrun stapler staple "$APP_BUNDLE"

# --- DMG with Applications symlink ---
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
DMG_STAGING="$BUILD_DIR/dmg-staging"
echo "Creating DMG..."
rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "Fanfrnoch" -srcfolder "$DMG_STAGING" \
    -ov -format UDZO "$DMG_PATH"
rm -rf "$DMG_STAGING"

echo "Signing DMG..."
codesign --force --timestamp --sign "$IDENTITY" "$DMG_PATH"

# --- Notarization ---
echo "Submitting $APP_NAME.dmg for notarization..."
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "Stapling notarization ticket to the DMG..."
xcrun stapler staple "$DMG_PATH"

# --- Sparkle appcast (auto-update) ---
# Signs the final (stapled) DMG with the EdDSA key from the Keychain and
# writes docs/appcast.xml for the GitHub Release that `gh release create`
# publishes as $APP_NAME-<version>.dmg (same bytes, so length + signature hold).
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
python3 scripts/make_appcast.py "$DMG_PATH" "$VERSION" \
    "https://github.com/jiripisa/fanfrnoch/releases/download/v$VERSION/$APP_NAME-$VERSION.dmg" \
    docs/appcast.xml

echo ""
echo "Done! Signed and notarized DMG: $DMG_PATH"
