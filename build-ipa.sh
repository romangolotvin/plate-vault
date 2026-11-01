#!/usr/bin/env bash
# Build a release IPA on macOS (requires Xcode + signing team).
# Usage:
#   ./build-ipa.sh                  # signed IPA → build/ios/ipa/
#   ./build-ipa.sh --no-codesign    # compile-only check (not installable)
#   TEAM_ID=XXXXXXXXXX ./build-ipa.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "iOS IPA can only be built on macOS with Xcode." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not on PATH" >&2
  exit 1
fi

NO_CODESIGN=0
for arg in "$@"; do
  case "$arg" in
    --no-codesign) NO_CODESIGN=1 ;;
  esac
done

echo "=== flutter pub get ==="
flutter pub get

echo "=== flutter test ==="
flutter test

if [[ "$NO_CODESIGN" -eq 1 ]]; then
  echo "=== flutter build ios --release --no-codesign ==="
  flutter build ios --release --no-codesign
  APP="build/ios/iphoneos/Runner.app"
  OUT_DIR="${BUILDS_DIR:-$ROOT/build/ios-dist}"
  mkdir -p "$OUT_DIR"
  STAMP="$(date +%Y%m%d-%H%M%S)"
  ZIP="$OUT_DIR/plate-vault-ios-unsigned-$STAMP.zip"
  ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
  echo "UNSIGNED_OK $ZIP"
  echo "Not installable on a device without signing. Use without --no-codesign for IPA."
  exit 0
fi

EXPORT_OPTS="$ROOT/ios/ExportOptions.plist"
if [[ ! -f "$EXPORT_OPTS" ]]; then
  echo "Missing $EXPORT_OPTS" >&2
  exit 1
fi

if [[ -n "${TEAM_ID:-}" ]]; then
  /usr/libexec/PlistBuddy -c "Set :teamID $TEAM_ID" "$EXPORT_OPTS" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :teamID string $TEAM_ID" "$EXPORT_OPTS"
fi

TEAM_NOW="$(/usr/libexec/PlistBuddy -c 'Print :teamID' "$EXPORT_OPTS" 2>/dev/null || true)"
if [[ -z "$TEAM_NOW" || "$TEAM_NOW" == YOUR_* ]]; then
  echo "Set Apple Team ID: TEAM_ID=XXXXXXXXXX ./build-ipa.sh" >&2
  echo "Or edit ios/ExportOptions.plist and Xcode Signing." >&2
  exit 1
fi

echo "=== flutter build ipa --release ==="
flutter build ipa --release --export-options-plist="$EXPORT_OPTS"

IPA="$(find build/ios/ipa -name '*.ipa' | head -1 || true)"
if [[ -z "$IPA" ]]; then
  echo "IPA_MISSING — open Xcode → Runner.xcworkspace, set Team, retry." >&2
  exit 1
fi

OUT_DIR="${BUILDS_DIR:-$ROOT/build/ios-dist}"
mkdir -p "$OUT_DIR"
DEST="$OUT_DIR/plate-vault-release.ipa"
cp -f "$IPA" "$DEST"
echo "IPA_OK $DEST"
ls -lh "$DEST"
