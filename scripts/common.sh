#!/bin/bash
# Shared metadata. VERSION is the only source of the release version.
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"
PROJECT_VERSION="$(tr -d '\r\n' < VERSION)"
if [[ ! "$PROJECT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "VERSION must contain a semantic version such as 1.0.0" >&2
  exit 1
fi
APP_PATH="$PROJECT_ROOT/build/release/ChatGPT Proxy Launcher.app"
RELEASE_DIR="$PROJECT_ROOT/dist/$PROJECT_VERSION"
DMG_NAME="ChatGPT-Proxy-Launcher-$PROJECT_VERSION-arm64.dmg"
SOURCE_NAME="ChatGPT-Proxy-Launcher-$PROJECT_VERSION-source.zip"
APP_SOURCES=(Sources/BrandMark.swift Sources/ProxyCore.swift Sources/LauncherModel.swift Sources/LauncherApp.swift)
SWIFT_FLAGS=(-swift-version 5 -target arm64-apple-macosx13.0
  -module-cache-path build/module-cache -file-compilation-dir .
  -debug-prefix-map "$PROJECT_ROOT=." -file-prefix-map "$PROJECT_ROOT=.")

require_macos() {
  if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
    echo "Building and GUI tests require an Apple Silicon Mac." >&2
    exit 1
  fi
  command -v swiftc >/dev/null
  command -v python3 >/dev/null
  mkdir -p build/module-cache
}
