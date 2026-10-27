#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
device="${1:-550FB504-578C-4B86-B9E3-57CF4A16F1CA}"
xcodegen generate
xcodebuild -project SystemStatus.xcodeproj -scheme SystemStatus \
  -destination "platform=iOS Simulator,id=$device" \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO test
