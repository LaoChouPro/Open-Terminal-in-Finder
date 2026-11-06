#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_NAME="FinderTerminal.app"
APP_PATH="${BUILD_DIR}/${APP_NAME}"
CONTENTS="${APP_PATH}/Contents"
MACOS="${CONTENTS}/MacOS"
PLUGINS="${CONTENTS}/PlugIns"
RESOURCES="${CONTENTS}/Resources"
APPEX_NAME="FinderTerminalExtension.appex"
APPEX_PATH="${PLUGINS}/${APPEX_NAME}"
APPEX_CONTENTS="${APPEX_PATH}/Contents"
APPEX_MACOS="${APPEX_CONTENTS}/MacOS"
APPEX_RESOURCES="${APPEX_CONTENTS}/Resources"

TARGET_ARCH="arm64-apple-macos14.0"

echo "=========================================="
echo " 🛠️  Building FinderTerminal for macOS"
echo "=========================================="

# 1. Clean previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${MACOS}" "${PLUGINS}" "${RESOURCES}" "${APPEX_MACOS}" "${APPEX_RESOURCES}"

# 2. Build AppIcon if not exists
if [ ! -f "${PROJECT_DIR}/Resources/AppIcon.icns" ]; then
    echo "🎨 Generating AppIcon.icns..."
    python3 "${PROJECT_DIR}/Resources/generate_icons.py"
fi
cp "${PROJECT_DIR}/Resources/AppIcon.icns" "${RESOURCES}/AppIcon.icns"

# 3. Compile FinderSync Extension (.appex)
echo "📦 Compiling FinderSync Extension..."
swiftc -O \
    -parse-as-library \
    -target "${TARGET_ARCH}" \
    -framework Cocoa \
    -framework FinderSync \
    "${PROJECT_DIR}/FinderTerminalExtension/FinderSync.swift" \
    -o "${APPEX_MACOS}/FinderTerminalExtension"

cp "${PROJECT_DIR}/FinderTerminalExtension/Info.plist" "${APPEX_CONTENTS}/Info.plist"

# 4. Codesign Extension with Sandbox Entitlements
echo "🔏 Signing Extension with App Sandbox..."
codesign --force --sign - \
    --entitlements "${PROJECT_DIR}/FinderTerminalExtension/FinderTerminalExtension.entitlements" \
    "${APPEX_PATH}"

# 5. Compile Host App (Menu Bar Agent)
echo "📦 Compiling FinderTerminal Host App..."
swiftc -O \
    -target "${TARGET_ARCH}" \
    -framework Cocoa \
    -framework ServiceManagement \
    -framework FinderSync \
    "${PROJECT_DIR}/FinderTerminal/main.swift" \
    "${PROJECT_DIR}/FinderTerminal/AppDelegate.swift" \
    "${PROJECT_DIR}/FinderTerminal/LaunchAtLogin.swift" \
    -o "${MACOS}/FinderTerminal"

cp "${PROJECT_DIR}/FinderTerminal/Info.plist" "${CONTENTS}/Info.plist"

# 6. Codesign Host App Bundle (do not use --deep to preserve extension entitlements)
echo "🔏 Signing Host App..."
codesign --force --sign - "${APP_PATH}"

echo "✅ Build completed successfully: ${APP_PATH}"

# 7. Install to /Applications
DEST_APP="/Applications/${APP_NAME}"
echo "=========================================="
echo " 🚀 Installing to ${DEST_APP}"
echo "=========================================="

# Terminate existing running instance if any
pkill -f "FinderTerminal" || true

rm -rf "${DEST_APP}"
cp -R "${APP_PATH}" "${DEST_APP}"

# Clear quarantine if present
xattr -dr com.apple.quarantine "${DEST_APP}" 2>/dev/null || true

# 8. Register with LaunchServices
echo "🔄 Registering with LaunchServices..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "${DEST_APP}"

# 9. Register & Enable Extension via pluginkit
DEST_APPEX="${DEST_APP}/Contents/PlugIns/${APPEX_NAME}"
echo "🔌 Registering FinderSync Plugin..."
pluginkit -a "${DEST_APPEX}"
pluginkit -e use -i "com.vibe.FinderTerminal.Extension"

# 10. Restart Finder so it loads the new extension immediately
echo "🔄 Restarting Finder..."
killall Finder || true

# 11. Launch FinderTerminal app
echo "🚀 Launching FinderTerminal in menu bar..."
open "${DEST_APP}"

echo "=========================================="
echo " 🎉 Installation Complete!"
echo " FinderTerminal is now running in your menu bar."
echo " Right-click anywhere in Finder to see '在终端中打开这里'!"
echo "=========================================="
