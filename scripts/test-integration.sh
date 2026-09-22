#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_macos
FIXTURE_ROOT="$(mktemp -d "$PWD/build/fixture.XXXXXX")"
FIXTURE="$FIXTURE_ROOT/ChatGPT Fixture.app"
mkdir -p "$FIXTURE/Contents/MacOS"
swiftc "${SWIFT_FLAGS[@]}" Tests/LaunchFixture.swift \
  -o "$FIXTURE/Contents/MacOS/LaunchFixture"
python3 - "$FIXTURE/Contents/Info.plist" <<'PY'
import plistlib,sys
with open(sys.argv[1], 'wb') as f:
    plistlib.dump({'CFBundleIdentifier':'local.chatgpt-proxy-launcher.fixture',
        'CFBundleName':'ChatGPT','CFBundleExecutable':'LaunchFixture','CFBundlePackageType':'APPL',
        'CFBundleShortVersionString':'0.0.0-test','ChromiumBaseVersion':'test-fixture'},f)
PY
codesign --force --sign - --timestamp=none "$FIXTURE"
swiftc "${SWIFT_FLAGS[@]}" -parse-as-library \
  Sources/ProxyCore.swift Sources/LauncherModel.swift Tests/LaunchIntegration.swift \
  -framework SwiftUI -framework AppKit -o build/launch-integration
build/launch-integration "$FIXTURE"
