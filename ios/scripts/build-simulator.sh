#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if command -v xcodegen >/dev/null 2>&1; then
  echo "Generating Xcode project with XcodeGen..."
  xcodegen generate
fi

echo "Building LegadoiOS for iOS Simulator..."
xcodebuild \
  -project LegadoiOS.xcodeproj \
  -scheme LegadoiOS \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  build

echo ""
echo "Built: ios/build/Build/Products/Debug-iphonesimulator/LegadoiOS.app"
echo "Install on a booted simulator with:"
echo "  xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/LegadoiOS.app"
