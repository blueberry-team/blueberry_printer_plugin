#!/bin/bash

# StarIO10 SDK 자동 설치 스크립트

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FRAMEWORK_DIR="$SCRIPT_DIR/StarIO10.xcframework"

if [ -d "$FRAMEWORK_DIR" ]; then
    echo "✅ StarIO10.xcframework already exists"
    exit 0
fi

echo "📦 Downloading StarIO10 SDK..."
cd "$SCRIPT_DIR"

# Star Micronics 공식 GitHub에서 다운로드
curl -L -o StarIO10.zip "https://github.com/star-micronics/StarXpand-SDK-iOS/releases/download/1.6.0/StarIO10.xcframework.zip"

if [ $? -ne 0 ]; then
    echo "❌ Failed to download StarIO10 SDK"
    exit 1
fi

echo "📂 Extracting StarIO10 SDK..."
unzip -q StarIO10.zip
rm StarIO10.zip

if [ -d "$FRAMEWORK_DIR" ]; then
    echo "✅ StarIO10 SDK installed successfully"
else
    echo "❌ Failed to extract StarIO10 SDK"
    exit 1
fi
