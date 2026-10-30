#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_macos
swiftc "${SWIFT_FLAGS[@]}" -parse-as-library Sources/Localization.swift Sources/AdditionalTranslations.swift \
  Sources/ProxyCore.swift Sources/LauncherModel.swift Tests/InstalledApplications.swift \
  -framework SwiftUI -framework AppKit -o build/installed-tests
build/installed-tests
