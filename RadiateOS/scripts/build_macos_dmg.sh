#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJ="$ROOT_DIR/RadiateOS.xcodeproj"
SCHEME="RadiateOS"
BUILD_DIR="$ROOT_DIR/build/macos"
APP_NAME="RadiateOS"
DMG_PATH="/Users/mostafanasr/Desktop/$APP_NAME.dmg"

mkdir -p "$BUILD_DIR"

echo "Building $APP_NAME for macOS..."
xcodebuild -project "$PROJ" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=macOS' \
  build

echo "Locating built app..."
APP_PATH="$(find ~/Library/Developer/Xcode/DerivedData -name "$APP_NAME.app" -type d | head -1)"
if [[ -z "$APP_PATH" ]]; then
  echo "App not found in DerivedData" >&2; exit 1
fi

echo "Staging app for DMG..."
STAGE="$BUILD_DIR/stage"
rm -rf "$STAGE" && mkdir -p "$STAGE"
cp -R "$APP_PATH" "$STAGE/"

echo "Creating DMG..."
rm -f "$DMG_PATH"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG_PATH"

echo "DMG created at: $DMG_PATH"
