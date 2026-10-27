#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p artifacts
xcodegen generate
xcodebuild -project SystemStatus.xcodeproj -scheme SystemStatus \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath "$HOME/Library/Developer/Xcode/DerivedData/SystemStatusArchive" \
  -archivePath artifacts/SystemStatus.xcarchive \
  -allowProvisioningUpdates archive
