#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="FinderTerminal.app"
APP_PATH="${PROJECT_DIR}/build/${APP_NAME}"
DEST_APP="/Applications/${APP_NAME}"
EXTENSION_ID="com.vibe.FinderTerminal.Extension"

"${PROJECT_DIR}/Scripts/build.sh"

echo "Installing to ${DEST_APP}"
echo "This will quit FinderTerminal and restart Finder."

# Match only the app's process name instead of unrelated command lines.
pkill -x FinderTerminal || true

rm -rf "${DEST_APP}"
ditto "${APP_PATH}" "${DEST_APP}"

# Local ad-hoc builds do not need a quarantine attribute.
xattr -dr com.apple.quarantine "${DEST_APP}" 2>/dev/null || true

echo "Registering app with LaunchServices..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "${DEST_APP}"

echo "Registering and enabling FinderSync extension..."
pluginkit -a "${DEST_APP}/Contents/PlugIns/FinderTerminalExtension.appex"
pluginkit -e use -i "${EXTENSION_ID}"

echo "Restarting Finder..."
killall Finder || true

open "${DEST_APP}"
echo "Installation complete. Enable ${EXTENSION_ID} in System Settings if prompted."
