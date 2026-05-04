#!/bin/bash

# SpeedBarrow DMG Creation Script
APP_NAME="SpeedBarrow"
DMG_NAME="${APP_NAME}.dmg"
APP_BUNDLE="${APP_NAME}.app"

echo "💿 Creating DMG for ${APP_NAME}..."

# Ensure the app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ ${APP_BUNDLE} not found. Please run build_app.sh first."
    exit 1
fi

# 1. Clean up old DMG
rm -f "$DMG_NAME"

# 2. Create temporary directory for DMG contents
mkdir -p "dmg_temp"
cp -R "$APP_BUNDLE" "dmg_temp/"

# 3. Create a symbolic link to /Applications
ln -s /Applications "dmg_temp/Applications"

# 4. Create the DMG
hdiutil create -volname "${APP_NAME}" -srcfolder "dmg_temp" -ov -format UDZO "$DMG_NAME"

# 5. Clean up
rm -rf "dmg_temp"

echo "✨ ${DMG_NAME} created successfully!"
