#!/usr/bin/env bash
# Prepare iOS deps on Mac before opening Xcode.
# Fixes: Missing package product 'FlutterGeneratedPluginSwiftPackage'
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Run this on the Mac (needs Xcode + CocoaPods)." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not on PATH" >&2
  exit 1
fi

echo "=== flutter clean ==="
flutter clean

echo "=== flutter pub get ==="
flutter pub get

if ! command -v pod >/dev/null 2>&1; then
  echo "CocoaPods missing. Install:"
  echo "  sudo gem install cocoapods"
  echo "  # or: brew install cocoapods"
  exit 1
fi

echo "=== pod install ==="
cd ios
pod install --repo-update
cd ..

echo "=== open workspace ==="
open ios/Runner.xcworkspace

echo "OK — in Xcode: Signing (Personal Team) → unique Bundle ID → ▶ Run"
