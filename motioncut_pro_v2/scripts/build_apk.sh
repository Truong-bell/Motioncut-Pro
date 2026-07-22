#!/bin/bash
set -e

echo "=========================================="
echo "  MotionCut Pro v2.0 - Build APK"
echo "=========================================="

export PATH="/usr/local/flutter/bin:$PATH"
export ANDROID_SDK_ROOT="/usr/local/android-sdk"
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

echo "[1/3] Cleaning..."
flutter clean > /dev/null 2>&1

echo "[2/3] Getting dependencies..."
flutter pub get > /dev/null 2>&1

echo "[3/3] Building release APK..."
flutter build apk --release

echo ""
echo "=========================================="
echo "  Build THÀNH CÔNG!"
echo "=========================================="
echo ""
echo "APK nằm ở:"
echo "  build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "Để tải về, chạy:"
echo "  cp build/app/outputs/flutter-apk/app-release.apk motioncut.apk"
echo ""
echo "Sau đó right-click file motioncut.apk → Download"
