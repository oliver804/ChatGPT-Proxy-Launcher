#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_macos
swiftc "${SWIFT_FLAGS[@]}" -D RENDER_PREVIEWS -parse-as-library \
  "${APP_SOURCES[@]}" Tests/RenderPreviews.swift \
  -framework SwiftUI -framework AppKit -o build/render-previews
build/render-previews
