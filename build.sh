#!/usr/bin/env bash
# Builds JupiterMenuBar.app from Swift sources without xcodebuild.
# Useful when the local Xcode install is missing CoreSimulator / IDESimulatorFoundation.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="JupiterMenuBar"
BUNDLE_ID="dev.raccoons.jupiter-menubar"
OUT_DIR="build-manual"
APP="$OUT_DIR/$APP_NAME.app"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
SRC="$(find jupiter-menubar -name '*.swift')"

mkdir -p "$OUT_DIR"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "→ Compiling Swift sources"
# shellcheck disable=SC2086
swiftc -O -target arm64-apple-macos13.0 -sdk "$SDK" \
  -o "$APP/Contents/MacOS/$APP_NAME" \
  $SRC

echo "→ Writing Info.plist"
cp jupiter-menubar/Resources/Info.plist "$APP/Contents/Info.plist"
plutil -replace CFBundleExecutable -string "$APP_NAME" "$APP/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$APP/Contents/Info.plist"
plutil -replace CFBundlePackageType -string "APPL" "$APP/Contents/Info.plist"

echo "→ Copying menu bar icon"
ICONSET="jupiter-menubar/Resources/Assets.xcassets/MenuBarIcon.imageset"
cp "$ICONSET/icon.png"    "$APP/Contents/Resources/MenuBarIcon.png"
cp "$ICONSET/icon@2x.png" "$APP/Contents/Resources/MenuBarIcon@2x.png"
cp "$ICONSET/icon@3x.png" "$APP/Contents/Resources/MenuBarIcon@3x.png"

echo "→ Ad-hoc signing"
codesign --force --sign - "$APP"

echo "✓ Built $APP"
echo "  Run with: open $APP"
