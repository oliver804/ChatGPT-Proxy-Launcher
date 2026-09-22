#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_macos
MOUNT_DIR="$(mktemp -d "$PROJECT_ROOT/build/mount.XXXXXX")"
hdiutil attach -readonly -nobrowse -mountpoint "$MOUNT_DIR" "$RELEASE_DIR/$DMG_NAME"
trap 'hdiutil detach "$MOUNT_DIR"' EXIT
MOUNTED_APP="$MOUNT_DIR/ChatGPT Proxy Launcher.app"
test -x "$MOUNTED_APP/Contents/MacOS/ChatGPTProxyLauncher"
test "$(readlink "$MOUNT_DIR/Applications")" = "/Applications"
test -f "$MOUNT_DIR/安装说明.txt"
test -f "$MOUNT_DIR/Installation.txt"
test -f "$MOUNT_DIR/LICENSE"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$MOUNTED_APP/Contents/Info.plist")" = "$PROJECT_VERSION"
codesign --verify --deep --strict "$MOUNTED_APP"
cmp "$APP_PATH/Contents/MacOS/ChatGPTProxyLauncher" "$MOUNTED_APP/Contents/MacOS/ChatGPTProxyLauncher"
ICON_FILE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$MOUNTED_APP/Contents/Info.plist")"
cmp "$APP_PATH/Contents/Resources/$ICON_FILE" "$MOUNTED_APP/Contents/Resources/$ICON_FILE"
python3 scripts/privacy-check.py --bundle "$MOUNTED_APP"
swiftc "${SWIFT_FLAGS[@]}" scripts/verify-icon.swift -o build/verify-icon
if [[ "${SKIP_SYSTEM_ICON_CHECK:-0}" == 1 ]]; then
  # Hosted CI runners may have no interactive icon service. Keep structural validation enabled.
  build/verify-icon "$MOUNTED_APP" --structural
else
  build/verify-icon "$MOUNTED_APP" build/verified-dmg-icon.png
fi
python3 scripts/checksums.py --verify
echo 'PASS: DMG, version, signature, icon, privacy checks and installation contents.'
