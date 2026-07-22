#!/bin/bash
set -e

echo "=========================================="
echo "  MotionCut Pro v2.0 - Codespace Setup"
echo "=========================================="

# 1. Cài các package cần thiết
echo "[1/6] Installing system packages..."
apt-get update -qq
apt-get install -y -qq git curl unzip xz-utils libglu1-mesa openjdk-17-jdk wget > /dev/null 2>&1

# 2. Cài Flutter
echo "[2/6] Installing Flutter..."
FLUTTER_ROOT="/usr/local/flutter"
if [ ! -d "$FLUTTER_ROOT" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_ROOT" > /dev/null 2>&1
fi
export PATH="$FLUTTER_ROOT/bin:$PATH"

# 3. Cài Android SDK
echo "[3/6] Installing Android SDK..."
ANDROID_SDK_ROOT="/usr/local/android-sdk"
mkdir -p "$ANDROID_SDK_ROOT"

if [ ! -d "$ANDROID_SDK_ROOT/cmdline-tools" ]; then
  cd "$ANDROID_SDK_ROOT"
  wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  unzip -q commandlinetools-linux-11076708_latest.zip
  mkdir -p cmdline-tools/latest
  mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
  rm -f commandlinetools-linux-11076708_latest.zip
fi

export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

# 4. Accept licenses & cài platform
echo "[4/6] Accepting Android licenses..."
yes | sdkmanager --licenses > /dev/null 2>&1 || true

echo "[5/6] Installing Android platform & build-tools..."
sdkmanager "platforms;android-34" "build-tools;34.0.0" "platform-tools" > /dev/null 2>&1

# 5. Pre-download dependencies
echo "[6/6] Getting Flutter dependencies..."
cd /workspaces/*/ 2>/dev/null || cd /workspaces/motioncut_pro_v2/ 2>/dev/null || true
flutter config --no-analytics > /dev/null 2>&1
flutter pub get > /dev/null 2>&1

echo ""
echo "=========================================="
echo "  Setup HOÀN TẤT!"
echo "=========================================="
echo ""
echo "Để build APK, chạy:"
echo "  bash scripts/build_apk.sh"
echo ""
echo "Hoặc chạy từng bước:"
echo "  flutter build apk --release"
echo ""
flutter doctor
