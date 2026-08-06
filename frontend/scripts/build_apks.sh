#!/usr/bin/env bash
# Build three release APK variants (production, emulator, local).
# Usage: ./scripts/build_apks.sh [LAN_IP]
# Output: build/apk-release/

set -euo pipefail
cd "$(dirname "$0")/.."

LAN_IP="${1:-${LOCAL_API_HOST:-}}"
if [[ -z "$LAN_IP" ]]; then
  LAN_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
fi
LAN_IP="${LAN_IP:-192.168.1.1}"

OUT_DIR="build/apk-release"
mkdir -p "$OUT_DIR"

build_one() {
  local flavor="$1"
  local api_host="$2"
  local out_name="$3"
  local target_platform="android-arm64"
  if [[ "$flavor" == "emulator" ]]; then
    target_platform="android-x64"
  fi
  echo ">> Building $flavor (API_HOST=$api_host, $target_platform)..."
  flutter build apk --flavor "$flavor" --release --dart-define="API_HOST=$api_host" --target-platform "$target_platform"
  cp "build/app/outputs/flutter-apk/app-${flavor}-release.apk" "$OUT_DIR/$out_name"
  echo "   Saved: $OUT_DIR/$out_name"
}

echo ""
echo "=== AirWatch — building 3 release APKs ==="
echo "Local LAN IP: $LAN_IP"
echo ""

build_one production "http://92.5.10.116" "airwatch-production.apk"
build_one emulator "10.0.2.2:8000" "airwatch-emulator.apk"
build_one local "${LAN_IP}:8000" "airwatch-local.apk"

echo ""
echo "Done. APKs are in $OUT_DIR/"
