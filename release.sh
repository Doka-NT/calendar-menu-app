#!/bin/bash

# Убедитесь, что все команды возвращают успешный статус
set -e

# xcodebuild -scheme "CalendarMenuApp" -workspace "CalendarMenuApp.xcodeproj/project.xcworkspace" -configuration Release clean archive -archivePath build/CalendarMenuApp.xcarchive
# Настройки
PROJECT_NAME="CalendarMenuApp"
BUILD_DIR="build"
DMG_NAME="$PROJECT_NAME.dmg"
RELEASE_DIR="dist"
GITHUB_REPO="Doka-NT/calendar-menu-app"

# Очистка предыдущих сборок
echo "Cleaning previous build..."
rm -rf "$BUILD_DIR"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Копирование .app в директорию для DMG
echo "Preparing DMG structure..."
mkdir -p "$BUILD_DIR/Release-dmg"
cp -R "$1" "$BUILD_DIR/Release-dmg/$PROJECT_NAME.app"

# Ad-hoc code signing to prevent "damaged" error on macOS
echo "Ad-hoc signing application..."
codesign --force --deep --sign - "$BUILD_DIR/Release-dmg/$PROJECT_NAME.app"

# Создание DMG пакета
echo "Creating DMG package..."
hdiutil create -volname "$PROJECT_NAME" -srcfolder "$BUILD_DIR/Release-dmg" -ov -format UDZO "$RELEASE_DIR/$DMG_NAME"

# Ad-hoc sign the DMG
echo "Ad-hoc signing DMG..."
codesign --force --sign - "$RELEASE_DIR/$DMG_NAME"
codesign --verify --verbose "$RELEASE_DIR/$DMG_NAME"

# Создание нового релиза на GitHub
echo "Creating GitHub release..."
NEW_TAG="v$(date +%Y%m%d%H%M%S)"
RELEASE_NAME="Release $NEW_TAG"
gh release create "$NEW_TAG" "$RELEASE_DIR/$DMG_NAME" --repo "$GITHUB_REPO" --title "$RELEASE_NAME" --notes "Auto-generated release"

echo "Release created successfully!"
