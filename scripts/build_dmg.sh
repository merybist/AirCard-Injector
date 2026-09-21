#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/AirCardInjector.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/AirCardInjector.app/Contents/Resources"
mkdir -p "$BUILD_DIR/AirCardInjector.app/Contents/Helpers"

echo "==> Compiling native macOS SwiftUI Universal binary (arm64 + x86_64)..."
xcrun -sdk macosx swiftc -O \
    -parse-as-library \
    -target arm64-apple-macos14.0 \
    "$ROOT/src/main.swift" \
    -o "$BUILD_DIR/AirCardInjector-arm64"

xcrun -sdk macosx swiftc -O \
    -parse-as-library \
    -target x86_64-apple-macos14.0 \
    "$ROOT/src/main.swift" \
    -o "$BUILD_DIR/AirCardInjector-x86_64"

lipo -create \
    "$BUILD_DIR/AirCardInjector-arm64" \
    "$BUILD_DIR/AirCardInjector-x86_64" \
    -output "$BUILD_DIR/AirCardInjector.app/Contents/MacOS/AirCardInjector"
rm -f "$BUILD_DIR/AirCardInjector-arm64" "$BUILD_DIR/AirCardInjector-x86_64"

cat << 'EOF' > "$BUILD_DIR/AirCardInjector.app/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AirCardInjector</string>
    <key>CFBundleIdentifier</key>
    <string>com.aircard.injector</string>
    <key>CFBundleName</key>
    <string>AirCardInjector</string>
    <key>CFBundleDisplayName</key>
    <string>AirCard Injector</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

if [ -f "$ROOT/assets/AppIcon.icns" ]; then
    echo "==> Copying AppIcon.icns into app bundle..."
    cp "$ROOT/assets/AppIcon.icns" "$BUILD_DIR/AirCardInjector.app/Contents/Resources/AppIcon.icns"
fi

if [ -d "/Applications/idevice_pair.app" ]; then
    echo "==> Embedding idevice_pair.app helper inside AirCardInjector.app..."
    cp -R "/Applications/idevice_pair.app" "$BUILD_DIR/AirCardInjector.app/Contents/Helpers/"
    codesign --force --deep --sign - "$BUILD_DIR/AirCardInjector.app/Contents/Helpers/idevice_pair.app"
fi

echo "==> Ad-hoc code-signing application bundle..."
codesign --force --deep --sign - "$BUILD_DIR/AirCardInjector.app"

DMG_PATH="$ROOT/build/AirCardInjector.dmg"
rm -f "$DMG_PATH"

DMG_CONTENT="$BUILD_DIR/DMG_Content"
rm -rf "$DMG_CONTENT"
mkdir -p "$DMG_CONTENT"

echo "==> Preparing DMG staging directory..."
cp -R "$BUILD_DIR/AirCardInjector.app" "$DMG_CONTENT/"

BG_IMG="$ROOT/assets/dmg_background.png"
VOL_ICON="$ROOT/assets/AppIcon.icns"

echo "==> Creating custom styled DMG with create-dmg..."
if command -v create-dmg >/dev/null 2>&1; then
    create-dmg \
        --volname "AirCard Injector" \
        --volicon "$VOL_ICON" \
        --background "$BG_IMG" \
        --window-pos 200 120 \
        --window-size 660 400 \
        --icon-size 110 \
        --text-size 13 \
        --icon "AirCardInjector.app" 175 195 \
        --hide-extension "AirCardInjector.app" \
        --app-drop-link 485 195 \
        --no-internet-enable \
        "$DMG_PATH" \
        "$DMG_CONTENT" || true
else
    echo "create-dmg not found, falling back to hdiutil..."
    hdiutil create -volname "AirCard Injector" -srcfolder "$DMG_CONTENT" -ov -format UDZO "$DMG_PATH"
fi

echo "==> DMG successfully created at: $DMG_PATH"
ls -lh "$DMG_PATH"
