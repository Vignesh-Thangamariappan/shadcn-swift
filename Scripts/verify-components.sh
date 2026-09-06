#!/bin/sh
# Typechecks every vendored SwiftUI component (they aren't part of the SPM
# package graph on purpose — they're copy-paste targets, not a dependency) plus
# UsageProbe.swift, which proves UI.Button coexists with SwiftUI.Button.
set -eu

cd "$(dirname "$0")/.."

xcrun --sdk iphonesimulator swiftc -typecheck -target arm64-apple-ios17.0-simulator \
  registry/swiftui/tokens/Theme.swift \
  registry/swiftui/tokens/Tokens.swift \
  registry/swiftui/button/Button.swift \
  registry/swiftui/card/Card.swift \
  Scripts/UsageProbe.swift

echo "OK: registry components typecheck, UI.Button does not shadow SwiftUI.Button"
