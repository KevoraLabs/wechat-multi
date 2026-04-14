#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/WeChatMulti.xcodeproj"
PROJECT_FILE="$PROJECT_DIR/project.pbxproj"
SCHEME="WeChatMulti"
BUILD_STAMP="$(date +%Y%m%d-%H%M%S)"
DERIVED_DATA_PATH="$ROOT_DIR/.build/package/$BUILD_STAMP/DerivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/$SCHEME.app"
DIST_DIR="$ROOT_DIR/dist"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

ensure_project() {
  if [[ -f "$PROJECT_FILE" ]]; then
    return
  fi

  require_command xcodegen
  (
    cd "$ROOT_DIR"
    xcodegen generate
  )
}

main() {
  require_command xcodebuild
  require_command ditto
  require_command shasum
  require_command /usr/libexec/PlistBuddy

  ensure_project
  mkdir -p "$DIST_DIR"

  xcodebuild \
    -project "$PROJECT_DIR" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build

  if [[ ! -d "$APP_PATH" ]]; then
    echo "Build succeeded but app bundle was not found: $APP_PATH" >&2
    exit 1
  fi

  local version
  local build_number
  local zip_name
  local zip_path
  local checksum

  version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
  build_number="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"
  zip_name="${SCHEME}-${version}-${build_number}.zip"
  zip_path="$DIST_DIR/$zip_name"

  ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$zip_path"
  checksum="$(shasum -a 256 "$zip_path" | awk '{print $1}')"

  cat <<EOF
Created package:
  $zip_path

SHA256:
  $checksum
EOF
}

main "$@"
