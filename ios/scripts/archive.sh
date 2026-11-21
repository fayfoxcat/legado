#!/usr/bin/env bash
set -eo pipefail

cd "$(dirname "$0")/.."

if [ -z "$DEVELOPMENT_TEAM" ]; then
  echo "Set DEVELOPMENT_TEAM to your Apple Developer Team ID." >&2
  exit 1
fi

if [ -z "$BUNDLE_ID" ]; then
  echo "Set BUNDLE_ID to a unique bundle identifier." >&2
  exit 1
fi

mkdir -p build

echo "Archiving LegadoiOS..."
xcodebuild \
  -project LegadoiOS.xcodeproj \
  -scheme LegadoiOS \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/LegadoiOS.xcarchive \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  -allowProvisioningUpdates \
  archive

echo "Exporting IPA..."
xcodebuild \
  -exportArchive \
  -archivePath build/LegadoiOS.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/export \
  -allowProvisioningUpdates

echo ""
echo "Exported to: ios/build/export/"
ls -la build/export
