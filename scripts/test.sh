#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_macos
python3 scripts/privacy-check.py
swiftc "${SWIFT_FLAGS[@]}" -parse-as-library Sources/Localization.swift Sources/ProxyCore.swift Tests/CoreTests.swift -o build/core-tests
build/core-tests
swiftc "${SWIFT_FLAGS[@]}" -parse-as-library Sources/Localization.swift Sources/ProxyCore.swift \
  Sources/LauncherModel.swift Tests/LanguageTests.swift -framework SwiftUI -framework AppKit -o build/language-tests
build/language-tests
