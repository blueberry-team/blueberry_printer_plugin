#!/bin/bash

# StarIO10 SDK 자동 설치 스크립트

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FRAMEWORK_DIR="$SCRIPT_DIR/StarIO10.xcframework"

if [ -d "$FRAMEWORK_DIR" ]; then
    echo "✅ StarIO10.xcframework already exists"
    exit 0
fi

echo "📦 Searching for StarIO10 SDK..."

# 1. Swift Package Manager 캐시에서 찾기
SPM_CACHE=$(find ~/Library/Developer/Xcode/DerivedData -name "StarIO10.xcframework" -type d 2>/dev/null | head -1)

if [ -n "$SPM_CACHE" ] && [ -d "$SPM_CACHE" ]; then
    echo "📂 Found in Swift Package Manager cache"
    cp -R "$SPM_CACHE" "$FRAMEWORK_DIR"
    echo "✅ StarIO10 SDK copied successfully from SPM cache"
    exit 0
fi

# 2. GitHub에서 클론하여 빌드
echo "📦 Cloning StarXpand-SDK-iOS from GitHub..."
cd "$SCRIPT_DIR"
TEMP_DIR=$(mktemp -d)
git clone --depth 1 https://github.com/star-micronics/StarXpand-SDK-iOS.git "$TEMP_DIR"

if [ $? -ne 0 ]; then
    echo "❌ Failed to clone StarXpand-SDK-iOS"
    rm -rf "$TEMP_DIR"
    exit 1
fi

if [ -d "$TEMP_DIR/StarIO10.xcframework" ]; then
    echo "📂 Copying StarIO10.xcframework..."
    cp -R "$TEMP_DIR/StarIO10.xcframework" "$FRAMEWORK_DIR"
    rm -rf "$TEMP_DIR"
    echo "✅ StarIO10 SDK installed successfully"
else
    echo "❌ StarIO10.xcframework not found in repository"
    rm -rf "$TEMP_DIR"
    exit 1
fi
