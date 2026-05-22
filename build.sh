#!/bin/bash
set -euo pipefail

APP_NAME="FreeGamesWatcher"
BUILD_DIR=".build"
APP_BUNDLE="Imperator Free Games.app"

echo "Building ${APP_NAME}..."
swift build -c release 2>&1

echo "Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/"
cp "Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/"

# Rename the executable to match CFBundleExecutable in Info.plist
# (Info.plist still references "FreeGamesWatcher" as the executable name)

echo "Signing app bundle..."
codesign --sign - --force --deep "${APP_BUNDLE}"

echo "Installing to /Applications..."
rm -rf "/Applications/${APP_BUNDLE}"
cp -R "${APP_BUNDLE}" "/Applications/${APP_BUNDLE}"

echo ""
echo "Build complete: /Applications/${APP_BUNDLE}"
echo "Run with: open '/Applications/${APP_BUNDLE}'"
