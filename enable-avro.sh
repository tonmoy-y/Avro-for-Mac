#!/bin/bash
# Re-register, enable and select Avro Keyboard as the current input source.
# Use this if Avro disappears from the input menu or typing stops working.
set -euo pipefail

APP="$HOME/Library/Input Methods/Avro Keyboard.app"
if [ ! -d "$APP" ]; then
  echo "Avro Keyboard.app not found in ~/Library/Input Methods. Run ./install.sh first." >&2
  exit 1
fi

swift - <<'EOF'
import Carbon

func sourceID(_ s: TISInputSource) -> String {
    guard let p = TISGetInputSourceProperty(s, kTISPropertyInputSourceID) else { return "" }
    return Unmanaged<CFString>.fromOpaque(p).takeUnretainedValue() as String
}

let url = URL(fileURLWithPath: NSHomeDirectory() + "/Library/Input Methods/Avro Keyboard.app") as CFURL
TISRegisterInputSource(url)

let all = TISCreateInputSourceList(nil, true).takeRetainedValue() as! [TISInputSource]
for s in all where sourceID(s).contains("AvroKeyboard") {
    TISEnableInputSource(s)
}

let enabled = TISCreateInputSourceList(nil, false).takeRetainedValue() as! [TISInputSource]
for s in enabled where sourceID(s).contains("AvroKeyboard") {
    TISSelectInputSource(s)
}

let current = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
print("Current input source:", sourceID(current))
EOF
