#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_PATH="${BUILD_DIR}/FinderTerminal.app"
CONTENTS="${APP_PATH}/Contents"
MACOS="${CONTENTS}/MacOS"
PLUGINS="${CONTENTS}/PlugIns"
RESOURCES="${CONTENTS}/Resources"
APPEX_PATH="${PLUGINS}/FinderTerminalExtension.appex"
APPEX_CONTENTS="${APPEX_PATH}/Contents"
APPEX_MACOS="${APPEX_CONTENTS}/MacOS"

ARCH="${ARCH:-$(uname -m)}"
case "${ARCH}" in
    arm64 | x86_64)
        ;;
    *)
        echo "Unsupported ARCH: ${ARCH}. Use arm64 or x86_64." >&2
        exit 2
        ;;
esac
TARGET_ARCH="${ARCH}-apple-macos14.0"

for tool in swiftc codesign plutil; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "Required tool not found: ${tool}. Install Xcode Command Line Tools." >&2
        exit 1
    fi
done

echo "Building FinderTerminal for ${TARGET_ARCH}"

# Remove only this app's previous output, leaving unrelated build artifacts alone.
rm -rf "${APP_PATH}"
mkdir -p "${MACOS}" "${PLUGINS}" "${RESOURCES}" "${APPEX_MACOS}"

plutil -lint \
    "${PROJECT_DIR}/FinderTerminal/Info.plist" \
    "${PROJECT_DIR}/FinderTerminalExtension/Info.plist" \
    "${PROJECT_DIR}/FinderTerminalExtension/FinderTerminalExtension.entitlements"

if [ ! -f "${PROJECT_DIR}/Resources/AppIcon.icns" ]; then
    echo "Generating AppIcon.icns (requires Python 3 and Pillow)..."
    python3 "${PROJECT_DIR}/Resources/generate_icons.py"
fi
cp "${PROJECT_DIR}/Resources/AppIcon.icns" "${RESOURCES}/AppIcon.icns"

echo "Compiling FinderSync extension..."
swiftc -O \
    -parse-as-library \
    -target "${TARGET_ARCH}" \
    -framework Cocoa \
    -framework FinderSync \
    "${PROJECT_DIR}/FinderTerminalExtension/FinderSync.swift" \
    -o "${APPEX_MACOS}/FinderTerminalExtension"

cp "${PROJECT_DIR}/FinderTerminalExtension/Info.plist" "${APPEX_CONTENTS}/Info.plist"

echo "Signing FinderSync extension..."
codesign --force --sign - \
    --entitlements "${PROJECT_DIR}/FinderTerminalExtension/FinderTerminalExtension.entitlements" \
    "${APPEX_PATH}"

echo "Compiling menu bar app..."
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

# Sign the host after the extension; --deep would replace the extension signature.
echo "Signing app bundle..."
codesign --force --sign - "${APP_PATH}"

codesign --verify --deep --strict "${APP_PATH}"
echo "Build completed: ${APP_PATH}"
