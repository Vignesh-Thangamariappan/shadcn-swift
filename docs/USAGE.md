# Usage guide

This walks through consuming shadcn-swift from a real iOS app project, both by
hand (CLI) and from a coding agent (MCP), then shows every component that
exists today.

## 1. Build the tools once

```bash
cd /path/to/shadcn-swift
swift build -c release
cp .build/release/shadcn-swift .build/release/shadcn-swift-mcp /usr/local/bin/
```

## 2. Wire up a consumer project (CLI)

From your app's repo root (wherever `Sources/` or your Xcode project lives):

```bash
shadcn-swift init --registry /path/to/shadcn-swift/registry/registry.json
```

This writes `components.json` (tracks what's installed — don't hand-edit the
`installed` array) and creates `Sources/UI/`. See what's available:

```bash
shadcn-swift list --registry /path/to/shadcn-swift/registry/registry.json
```

```
tokens
  Design tokens (color, spacing, radius, typography) exposed via SwiftUI Environment
button  (needs: tokens)
  Primary/secondary/ghost button style
card  (needs: tokens, button)
  Card container with optional trailing action button
badge  (needs: tokens)
  Small status/label pill (primary/secondary/outline)
input  (needs: tokens)
  Styled text field with focus ring and an invalid/error state
toggle  (needs: tokens)
  Themed on/off switch (custom ToggleStyle)
```

Add what you need — dependencies come along automatically:

```bash
shadcn-swift add card badge input toggle
```

```
add    tokens  -> Sources/UI/tokens/
add    badge   -> Sources/UI/badge/
add    input   -> Sources/UI/input/
add    toggle  -> Sources/UI/toggle/
add    button  -> Sources/UI/button/
add    card    -> Sources/UI/card/
```

`tokens` is emitted once even though three different components need it.
Drag `Sources/UI/` into your Xcode project (or it's already on your source
path if you build with SwiftPM/Tuist) and you're building.

Already-installed components are skipped on a re-run — safe to call `add`
again from a script or CI without duplicating work. Pass `--force` to
re-copy and overwrite (you'll lose any hand-edits to that component).

## 3. Wire up a consumer project (MCP / agent)

Add to the project's `.mcp.json` (or your agent's MCP config):

```json
{
  "mcpServers": {
    "shadcn-swift": {
      "command": "/usr/local/bin/shadcn-swift-mcp",
      "env": {
        "SHADCN_SWIFT_REGISTRY": "/path/to/shadcn-swift/registry/registry.json"
      }
    }
  }
}
```

An agent's flow, mirroring what the CLI does internally:

1. `list_components` — see what's available and what depends on what
2. `resolve_plan(["card"])` → `[tokens, button, card]`, dependencies first
3. `get_component` once per name in that order — each call returns that
   component's own file(s) with full contents
4. Write the files into the project itself (through its normal file-write
   tool), so you get the same diff-and-review step you'd get from typing
   `shadcn-swift add` by hand

There is no `add_component` tool on purpose — see the MCP section of the
main README for why.

## 4. Using the components

Every component is namespaced under `UI`, so it never collides with a real
SwiftUI type of the same name (`Button`, `Toggle`, ...).

### Theming

Everything reads from `Environment(\.uiTheme)`, seeded by `UI.Theme.default`.
Override per-subtree with `.uiTheme(_:)`:

```swift
import SwiftUI

MyRootView()
    .uiTheme(
        UI.Theme(
            colors: .default,          // or your own UI.Theme.Colors(...)
            spacing: .default,
            radius: UI.Theme.Radius(sm: 4, md: 6, lg: 10),
            typography: .default
        )
    )
```

### Button

```swift
UI.Button("Continue") {
    submit()
}

UI.Button("Cancel", variant: .secondary) { dismiss() }
UI.Button(variant: .ghost, action: { showInfo() }) {
    Image(systemName: "info.circle")
}
```

### Card

```swift
UI.Card(title: "Storage", actionTitle: "Manage", action: { openStorage() }) {
    Text("42 GB of 100 GB used")
}
```

### Badge

```swift
UI.Badge("New")
UI.Badge("Draft", variant: .secondary)
UI.Badge("Beta", variant: .outline)
```

### Input

```swift
@State private var email = ""

UI.Input("Email", text: $email, isInvalid: !email.contains("@"))
UI.Input("Password", text: $password, isSecure: true)
```

`UI.Input` tracks its own focus ring internally — it does not accept an
external `FocusState` binding. If a screen needs to programmatically focus a
field (autofocus on appear, focus-next on submit), use a bare SwiftUI
`TextField`/`SecureField` with your own `@FocusState` on that screen instead.
See the deviation note at the top of `input/Input.swift`.

### Toggle

```swift
@State private var notificationsEnabled = true

UI.Toggle("Notifications", isOn: $notificationsEnabled)
```

## 5. Verifying a change to this repo

If you're editing components in this repo (not just consuming them):

```bash
swift test                        # dependency-resolution unit tests
Scripts/verify-components.sh      # typechecks every registry/swiftui/**/*.swift
                                   # against the real iOS SDK, plus Scripts/UsageProbe.swift
```

`UsageProbe.swift` is the thing that actually proves `UI.Button`/`UI.Toggle`
don't shadow `SwiftUI.Button`/`SwiftUI.Toggle` — add a line there exercising
any new component so the probe keeps covering what's shipped.
