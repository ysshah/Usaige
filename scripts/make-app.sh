#!/usr/bin/env bash
# Build Usaige in release mode and assemble a proper .app bundle.
# Usage: ./scripts/make-app.sh
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Usaige"
BUNDLE_ID="com.ys.usaige"
APP_DIR="${APP_NAME}.app"
CONTENTS="${APP_DIR}/Contents"

echo "==> swift build -c release"
swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)/${APP_NAME}"

echo "==> assembling ${APP_DIR}"
rm -rf "${APP_DIR}"
mkdir -p "${CONTENTS}/MacOS" "${CONTENTS}/Resources"
cp "${BIN_PATH}" "${CONTENTS}/MacOS/${APP_NAME}"

cat > "${CONTENTS}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>     <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>      <string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key>      <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>1.0</string>
    <key>CFBundleVersion</key>         <string>1</string>
    <key>LSMinimumSystemVersion</key>  <string>26.0</string>
    <key>LSUIElement</key>             <true/>
    <key>NSHumanReadableCopyright</key><string>Personal use</string>
</dict>
</plist>
PLIST

echo "==> ad-hoc codesign"
# Ad-hoc signing gives the bundle a stable identity for this binary, so the
# Keychain "Always Allow" decision persists until the binary is rebuilt.
codesign --force --sign - --identifier "${BUNDLE_ID}" "${APP_DIR}" >/dev/null 2>&1 || \
  echo "   (codesign skipped/failed — app still runs, may re-prompt for Keychain)"

echo "==> done: ${APP_DIR}"
echo "Run with:  open ./${APP_DIR}"
