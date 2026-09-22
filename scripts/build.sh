#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_macos

# Only this generated output is replaced; never package an old bundle with stale resources.
python3 - "$APP_PATH" <<'PY'
from pathlib import Path
import shutil,sys
app = Path(sys.argv[1])
if app.is_symlink():
    raise SystemExit('Refusing to build through a symlink')
if app.exists():
    shutil.rmtree(app)
(app / 'Contents/MacOS').mkdir(parents=True)
(app / 'Contents/Resources').mkdir()
PY
swiftc "${SWIFT_FLAGS[@]}" -O -parse-as-library -module-name ChatGPTProxyLauncher \
  "${APP_SOURCES[@]}" -framework SwiftUI -framework AppKit \
  -o "$APP_PATH/Contents/MacOS/ChatGPTProxyLauncher"
python3 - "$APP_PATH" "$PROJECT_VERSION" <<'PY'
from pathlib import Path
import plistlib,sys
app, version = Path(sys.argv[1]), sys.argv[2]
info = plistlib.loads(Path('Resources/Info.plist').read_bytes())
info.update(CFBundleShortVersionString=version, CFBundleVersion=version)
(app / 'Contents/Info.plist').write_bytes(plistlib.dumps(info, sort_keys=False))
PY
cp Resources/Credits.html LICENSE "$APP_PATH/Contents/Resources/"
swiftc "${SWIFT_FLAGS[@]}" -parse-as-library Sources/BrandMark.swift scripts/make-icon.swift \
  -framework SwiftUI -framework AppKit -o build/make-icon
ICON_FILE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$APP_PATH/Contents/Info.plist")"
build/make-icon "$APP_PATH/Contents/Resources/$ICON_FILE"
strip -S "$APP_PATH/Contents/MacOS/ChatGPTProxyLauncher"
codesign --force --sign - --timestamp=none "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"
python3 scripts/privacy-check.py --bundle "$APP_PATH"
echo "Built ChatGPT Proxy Launcher $PROJECT_VERSION (arm64)."
