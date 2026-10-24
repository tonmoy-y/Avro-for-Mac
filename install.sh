#!/bin/bash
# Build Avro Keyboard for Apple Silicon and install it as an input method.
set -euo pipefail

cd "$(dirname "$0")"
BUILD_DIR="$(mktemp -d)"
DEST="$HOME/Library/Input Methods"

xcodebuild -project AvroKeyboard.xcodeproj -configuration Release \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" \
  MACOSX_DEPLOYMENT_TARGET=12.0 SYMROOT="$BUILD_DIR" build

APP="$BUILD_DIR/Release/Avro Keyboard.app"
codesign --force --deep --sign - "$APP"

mkdir -p "$DEST"
pkill -f "Avro Keyboard.app/Contents/MacOS" || true
if [ -d "$DEST/Avro Keyboard.app" ]; then
  mv "$DEST/Avro Keyboard.app" "$DEST/Avro Keyboard.app.bak.$(date +%s)"
fi
cp -R "$APP" "$DEST/"
xattr -cr "$DEST/Avro Keyboard.app"

echo "Installed. Log out and back in, then enable it in System Settings > Keyboard > Input Sources."
