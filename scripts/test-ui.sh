#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_macos
swiftc "${SWIFT_FLAGS[@]}" -D RENDER_PREVIEWS -parse-as-library \
  "${APP_SOURCES[@]}" Tests/DockLifecycleTests.swift \
  -framework SwiftUI -framework AppKit -o build/dock-lifecycle-tests
build/dock-lifecycle-tests
swiftc "${SWIFT_FLAGS[@]}" -parse-as-library Sources/BrandMark.swift Tests/MenuBarIconTests.swift \
  -framework SwiftUI -framework AppKit -o build/menu-icon-tests
build/menu-icon-tests
