#!/usr/bin/env bash
set -euo pipefail

# money_tracer build+install helper
# This script is NOT recommended for Apple Silicon (M1/M2/M3) Macs.
# Use GitHub Actions instead: push to GitHub and download APK from Actions artifacts.
# See README.md for instructions.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

INSTALL=false
ADB_PATH="adb"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)
      INSTALL=true
      shift
      ;;
    --adb)
      ADB_PATH="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: bash scripts/build_and_install.sh [--install] [--adb PATH]"
      echo ""
      echo "NOTE: This script does NOT work on Apple Silicon (M1/M2/M3) Macs."
      echo "Use GitHub Actions instead (see README.md)."
      echo ""
      echo "Options:"
      echo "  --install   Install APK to connected device(s)"
      echo "  --adb PATH  Custom adb path (default: adb)"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1"
      exit 1
      ;;
  esac
done

# Check if running on Apple Silicon
arch=$(uname -m)
if [[ "$arch" == "arm64" ]]; then
  echo "================================================"
  echo "WARNING: Apple Silicon (arm64) detected!"
  echo "================================================"
  echo ""
  echo "Docker-based Flutter builds do NOT work on Apple Silicon Macs"
  echo "due to architecture incompatibility (x86_64 vs arm64)."
  echo ""
  echo "Please use GitHub Actions instead:"
  echo "  1. Push code to GitHub"
  echo "  2. Go to Actions tab → Build Android APK"
  echo "  3. Download APK from artifacts"
  echo ""
  echo "See README.md for detailed instructions."
  echo ""
  echo "================================================"
  exit 1
fi

apk_path="build/app/outputs/flutter-apk/app-release.apk"
mkdir -p build/app/outputs/flutter-apk

echo "[*] Building APK using GitHub subosito/flutter-action compatible setup..."
echo "[*] This only works on x86_64/amd64 hosts."
echo ""

# Use a known-good x86_64 image
IMAGE_NAME="ghcr.io/cirruslabs/flutter:stable"
echo "[*] Using: $IMAGE_NAME"
echo "[*] Running: flutter pub get"
if ! docker run --rm -v "$PWD":/app -w /app "$IMAGE_NAME" flutter pub get; then
  echo "[error] flutter pub get failed"
  echo "[info] Consider using GitHub Actions (see README.md)"
  exit 1
fi

echo ""
echo "[*] Running: flutter build apk --release"
if ! docker run --rm -v "$PWD":/app -w /app "$IMAGE_NAME" flutter build apk --release; then
  echo "[error] APK build failed"
  echo "[info] Consider using GitHub Actions (see README.md)"
  exit 1
fi

if [[ ! -f "$apk_path" ]]; then
  echo "[error] APK not found at $apk_path"
  exit 1
fi
echo "[ok] APK built successfully: $apk_path"

# Optionally install
if [[ "$INSTALL" == true ]]; then
  echo "[*] Installing APK to device(s)..."
  if ! command -v "$ADB_PATH" >/dev/null 2>&1; then
    echo "[error] adb not found at '$ADB_PATH'"
    echo "[info] Install: brew install android-platform-tools"
    exit 1
  fi

  devices=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')
  if [[ -z "$devices" ]]; then
    echo "[error] No devices connected. Enable USB debugging and try again."
    adb devices
    exit 1
  fi

  for d in $devices; do
    echo "[*] Installing to device: $d"
    adb -s "$d" install -r "$apk_path"
  done
  echo "[ok] Install complete"
fi

echo "[done]"
