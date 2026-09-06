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
context-menu  (needs: tokens, dropdown-menu)
  Themed wrapper over native .contextMenu, reusing dropdown-menu's item model
...
```

(25 components today, not all shown here — this list changes; `shadcn-swift
list` is the source of truth, and section 4 below has a call site for each.)

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

`init --registry` accepts a relative or absolute path; whatever you pass is
what lands in `components.json`. A path relative to the consumer project
(e.g. `../shadcn-swift/registry/registry.json`) travels with a clone of that
project — an absolute path (as in the examples above) does not, so if you
commit `components.json`, know that the `registryPath` field is then
machine-local unless every clone has this repo at the same absolute path.

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

There is no `add_component` tool on purpose. The point of the vendored model
is that a human reviews what lands in their project, and a component they've
hand-edited must never get silently clobbered by an agent's tool call — so
writing stays with `shadcn-swift add`, typed by hand, or the agent's own
normal file-write tool.

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

### Label

```swift
UI.Label("Email address")
```

### Separator

```swift
UI.Separator()             // horizontal, fills available width
UI.Separator(.vertical)    // needs a fixed height from its container
```

### Avatar

```swift
UI.Avatar(name: "Ada Lovelace")                                   // initials fallback: "AL"
UI.Avatar(name: "Ada Lovelace", imageURL: profileImageURL, size: 56)
```

### ProgressBar

```swift
UI.ProgressBar(value: downloadProgress)   // 0...1, clamped
```

### Skeleton

```swift
UI.Skeleton()
    .frame(height: 16)
    .frame(maxWidth: 200)
```

### Checkbox

```swift
@State private var acceptedTerms = false

UI.Checkbox("Accept terms", isOn: $acceptedTerms)
UI.Checkbox(isOn: $acceptedTerms)   // no label — just the box
```

### RadioGroup

Generic over any `Hashable` option type — a `String` enum works just as well:

```swift
@State private var plan = "free"

UI.RadioGroup(options: ["free", "pro", "team"], selection: $plan) { option in
    option.capitalized
}
```

### Alert

```swift
UI.Alert("Update available", message: "Version 2.1 is ready to install.")
UI.Alert("Something went wrong", message: error.localizedDescription, variant: .destructive)
```

### TextArea

Requires iOS 16+ (`.scrollContentBackground`). Same focus caveat as `UI.Input`:

```swift
@State private var notes = ""

UI.TextArea("Write something...", text: $notes)
UI.TextArea("Required", text: $notes, isInvalid: notes.isEmpty, minHeight: 140)
```

### Tabs

Generic over any `Hashable` tag — content is provided per selected tag:

```swift
@State private var tab = "profile"

UI.Tabs(
    items: [(tag: "profile", title: "Profile"), (tag: "settings", title: "Settings")],
    selection: $tab
) { selected in
    switch selected {
    case "profile": ProfileView()
    default: SettingsView()
    }
}
```

### Select

```swift
@State private var plan = "pro"

UI.Select(selection: $plan, options: ["free", "pro", "team"]) { $0.capitalized }
```

### DropdownMenu

```swift
UI.DropdownMenu("Options", items: [
    UI.MenuItem("Edit", systemImage: "pencil", action: { edit() }),
    UI.MenuItem("Delete", systemImage: "trash", isDestructive: true, action: { delete() })
])
```

### Combobox

Self-contained — owns its own sheet + search internally, no external
`Binding<Bool>` to manage:

```swift
@State private var framework = ""

UI.Combobox("Select framework", options: ["SwiftUI", "UIKit", "Compose"], selection: $framework)
```

### Sheet, Dialog, Popover, ConfirmationDialog — presentation modifiers

These four apply to a trigger view you already have, driven by an external
`Binding<Bool>` — same shape as `.sheet(isPresented:)`, just themed and
`ui`-prefixed:

```swift
@State private var showSheet = false
@State private var showDialog = false
@State private var showPopover = false
@State private var showConfirm = false

Button("Open sheet") { showSheet = true }
    .uiSheet(isPresented: $showSheet) {
        Text("Sheet content")
    }

Button("Delete") { showDialog = true }
    .uiDialog(isPresented: $showDialog) {
        VStack(spacing: 12) {
            Text("Delete project?").font(.headline)
            Text("This action can't be undone.")
        }
    }

Button("Info") { showPopover = true }
    .uiPopover(isPresented: $showPopover) {
        Text("Popover content").frame(width: 200)
    }

Button("Delete") { showConfirm = true }
    .uiConfirmationDialog(
        isPresented: $showConfirm,
        title: "Delete this item?",
        message: "This can't be undone.",
        confirmTitle: "Delete",
        isDestructive: true,
        onConfirm: { delete() }
    )
```

`uiDialog` uses `.fullScreenCover` under the hood (real modal semantics and
accessibility focus trapping) rather than a custom overlay — see the
deviation note in `dialog/Dialog.swift` for why a hand-rolled `.overlay`
version is the wrong call here. `uiPopover` forces
`.presentationCompactAdaptation(.popover)` so it stays a popover on iPhone
instead of silently becoming a sheet.

### Tooltip, ContextMenu — gesture-driven, no external binding

```swift
Image(systemName: "info.circle")
    .uiTooltip("This explains what the icon means")

RowView(item)
    .uiContextMenu([
        UI.MenuItem("Edit", systemImage: "pencil", action: { edit(item) }),
        UI.MenuItem("Delete", systemImage: "trash", isDestructive: true, action: { delete(item) })
    ])
```

Both trigger on a gesture (long-press) rather than a binding you control, so
— unlike the four above — their `#Preview` can only show the trigger at
rest; long-press on a real device or simulator to see the revealed content.

## 5. Seeing a component before you write any code

Every component file carries its own `#Preview` block(s), gated behind
`#if DEBUG` so none of it reaches a release build. Open the file in Xcode —
either straight from this repo (`registry/swiftui/<name>/*.swift`) or from
its vendored copy in your own project (`Sources/UI/<name>/*.swift`) — and
the canvas renders that component's variants live: `UI.Button`'s three
variants plus a disabled state, `UI.Alert`'s default and destructive
banners, `UI.Tabs` actually switching between tabs, and so on. This is the
same role shadcn.com's per-component demo page plays, just inside Xcode
instead of a browser, and it travels with the component wherever `add`
copies it.

## 6. Verifying a change to this repo

If you're editing components in this repo (not just consuming them):

```bash
swift test                        # dependency-resolution unit tests
Scripts/verify-components.sh      # typechecks every registry/swiftui/**/*.swift
                                   # against the real iOS SDK, plus Scripts/UsageProbe.swift
```

`UsageProbe.swift` is the thing that actually proves `UI.Button`/`UI.Toggle`
don't shadow `SwiftUI.Button`/`SwiftUI.Toggle` — add a line there exercising
any new component so the probe keeps covering what's shipped.
