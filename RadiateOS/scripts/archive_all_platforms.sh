#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJ="$ROOT_DIR/RadiateOS.xcodeproj"
SCHEME="RadiateOS"
OUT_DIR="$ROOT_DIR/build"
mkdir -p "$OUT_DIR"

declare -A DESTS=(
  [ios]="generic/platform=iOS"
  [iossim]="generic/platform=iOS Simulator"
  [macos]="generic/platform=macOS"
  [watchos]="generic/platform=watchOS"
  [watchsim]="generic/platform=watchOS Simulator"
  [xros]="generic/platform=visionOS"
  [xrossim]="generic/platform=visionOS Simulator"
)

for k in "${!DESTS[@]}"; do
  DEST="${DESTS[$k]}"
  ARCHIVE_PATH="$OUT_DIR/$k/RadiateOS.xcarchive"
  mkdir -p "$(dirname "$ARCHIVE_PATH")"
  echo "Archiving for $k ($DEST) ..."
  xcodebuild -project "$PROJ" -scheme "$SCHEME" -configuration Release \
    -destination "$DEST" archive -archivePath "$ARCHIVE_PATH" | xcpretty || true
  echo "$k archive at $ARCHIVE_PATH (if succeeded)"
  if [[ "$k" != macos ]]; then
    EXPORT_PATH="$OUT_DIR/$k/export"
    mkdir -p "$EXPORT_PATH"
    xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" \
      -exportOptionsPlist /dev/stdin \
      -exportPath "$EXPORT_PATH" <<<'<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>method</key><string>ad-hoc</string><key>signingStyle</key><string>automatic</string><key>destination</key><string>export</string></dict></plist>' | xcpretty || true
    echo "$k export at $EXPORT_PATH (if succeeded)"
  fi
done

echo "Done."
