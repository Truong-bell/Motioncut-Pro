#!/bin/bash
set -e

echo "=========================================="
echo "  MotionCut Pro v2.0 - Full Auto Build"
echo "=========================================="

# Setup
bash scripts/setup_codespace.sh

# Build
bash scripts/build_apk.sh

echo ""
echo "✅ HOÀN TẤT! Tìm file motioncut.apk để tải về."
