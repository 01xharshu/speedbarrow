#!/bin/bash

# SpeedBarrow Build Script
# This script creates a proper macOS .app bundle from the source files.

APP_NAME="SpeedBarrow"
BUNDLE_DIR="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
# Use the local icon the user provided
ICON_SOURCE="Assets.xcassets/AppIcon.appiconset/speedbarrow_app_icon_1777924928718 1.png"

echo "🚀 Building ${APP_NAME}.app..."

# 1. Create bundle structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 2. Compile Swift files
echo "🛠️ Compiling Swift files..."
swiftc -o "${MACOS_DIR}/${APP_NAME}" \
    SpeedBarApp.swift \
    ProcessMonitor.swift \
    StatusBarController.swift \
    Views/MainView.swift \
    Views/PopoverView.swift \
    -sdk $(xcrun --show-sdk-path --sdk macosx) \
    -target arm64-apple-macosx13.0 \
    -framework SwiftUI \
    -framework AppKit

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed."
    exit 1
fi

# 3. Create Info.plist
echo "📝 Creating Info.plist..."
cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SpeedBarrow</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.speedbarrow.app</string>
    <key>CFBundleName</key>
    <string>SpeedBarrow</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <string>NO</string>
</dict>
</plist>
EOF

# 4. Generate Icon (.icns)
echo "🎨 Generating icon..."
if [ -f "$ICON_SOURCE" ]; then
    # Create temporary iconset
    ICONSET="AppIcon.iconset"
    mkdir -p "$ICONSET"
    # Create multiple sizes for a proper icns
    sips -z 1024 1024 "$ICON_SOURCE" --out "${ICONSET}/icon_512x512@2x.png" > /dev/null 2>&1
    sips -z 512 512 "$ICON_SOURCE" --out "${ICONSET}/icon_512x512.png" > /dev/null 2>&1
    sips -z 256 256 "$ICON_SOURCE" --out "${ICONSET}/icon_256x256.png" > /dev/null 2>&1
    sips -z 128 128 "$ICON_SOURCE" --out "${ICONSET}/icon_128x128.png" > /dev/null 2>&1
    sips -z 32 32 "$ICON_SOURCE" --out "${ICONSET}/icon_32x32.png" > /dev/null 2>&1
    sips -z 16 16 "$ICON_SOURCE" --out "${ICONSET}/icon_16x16.png" > /dev/null 2>&1
    
    iconutil -c icns "$ICONSET" -o "${RESOURCES_DIR}/AppIcon.icns"
    rm -rf "$ICONSET"
    echo "✅ Icon generated."
else
    echo "⚠️ Icon source not found at $ICON_SOURCE. Skipping icon generation."
fi

echo "✨ Build Complete! You can now run ${APP_NAME}.app"
