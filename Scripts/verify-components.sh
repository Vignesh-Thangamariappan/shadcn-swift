#!/bin/sh
# Typechecks every vendored SwiftUI component (they aren't part of the SPM
# package graph on purpose — they're copy-paste targets, not a dependency) plus
# UsageProbe.swift, which proves UI.Button coexists with SwiftUI.Button.
#
# Globs registry/swiftui/**/*.swift on purpose: a hardcoded file list silently
# stops covering a new component the moment someone forgets to add it here.
set -eu

cd "$(dirname "$0")/.."

# shellcheck disable=SC2046
xcrun --sdk iphonesimulator swiftc -typecheck -target arm64-apple-ios17.0-simulator \
  $(find registry/swiftui -name '*.swift' | sort) \
  Scripts/UsageProbe.swift

echo "OK: registry components typecheck, UI.Button does not shadow SwiftUI.Button"
