#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
bash scripts/build.sh
python3 scripts/privacy-check.py
mkdir -p "$RELEASE_DIR"
STAGING_DIR="$(mktemp -d "$PROJECT_ROOT/build/dmg-stage.XXXXXX")"
ditto --norsrc --noextattr "$APP_PATH" "$STAGING_DIR/ChatGPT Proxy Launcher.app"
ln -s /Applications "$STAGING_DIR/Applications"
cp Resources/安装说明.txt Resources/Installation.txt LICENSE "$STAGING_DIR/"
hdiutil create -volname "ChatGPT Proxy Launcher" -srcfolder "$STAGING_DIR" \
  -ov -format UDZO "$RELEASE_DIR/$DMG_NAME"
hdiutil verify "$RELEASE_DIR/$DMG_NAME"
python3 scripts/export-source.py
python3 scripts/checksums.py
printf 'Release files: dist/%s/\n' "$PROJECT_VERSION"
