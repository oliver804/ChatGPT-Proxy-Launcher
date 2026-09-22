#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_macos
python3 scripts/privacy-check.py
swiftc "${SWIFT_FLAGS[@]}" -parse-as-library Sources/ProxyCore.swift Tests/CoreTests.swift -o build/core-tests
build/core-tests
