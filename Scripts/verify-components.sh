#!/bin/sh
# Typechecks every vendored SwiftUI component (they aren't part of the SPM
# package graph on purpose — they're copy-paste targets, not a dependency) plus
# UsageProbe.swift, which proves UI.Button coexists with SwiftUI.Button.
#
# Globs registry/swiftui/**/*.swift on purpose: a hardcoded file list silently
# stops covering a new component the moment someone forgets to add it here.
#
# -D DEBUG is required: each component's #if DEBUG / #Preview block (the
# Xcode-canvas presentation reference, same convention as EDS-iOS) is
# otherwise invisible to the preprocessor here and would typecheck as an
# empty file even if genuinely broken.
set -eu

cd "$(dirname "$0")/.."

# shellcheck disable=SC2046
xcrun --sdk iphonesimulator swiftc -typecheck -D DEBUG -target arm64-apple-ios17.0-simulator \
  $(find registry/swiftui -name '*.swift' | sort) \
  Scripts/UsageProbe.swift

echo "OK: registry components + #Preview blocks typecheck, UI.Button does not shadow SwiftUI.Button"
