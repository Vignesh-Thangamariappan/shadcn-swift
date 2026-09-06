# Usage guide

This walks through consuming shadcn-swift from a real iOS app project, both by
hand (CLI) and from a coding agent (MCP), then shows every component that
exists today.

## 1. Install the tools once

Prebuilt universal binaries (arm64 + x86_64), with `registry/` bundled
right next to them, are attached to every
[release](https://github.com/Vignesh-Thangamariappan/shadcn-swift/releases/latest):

```bash
mkdir -p ~/.local/share/shadcn-swift
curl -L https://github.com/Vignesh-Thangamariappan/shadcn-swift/releases/latest/download/shadcn-swift-macos-universal.tar.gz \
  | tar -xz -C ~/.local/share/shadcn-swift
echo 'export PATH="$HOME/.local/share/shadcn-swift:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

**Keep the binaries and `registry/` together** — both tools look for a
`registry/registry.json` sitting next to wherever they're actually
running from (following symlinks), and fall back to a Homebrew-style
`../share/shadcn-swift/registry/registry.json` layout, before giving up
and requiring an explicit `--registry` / `SHADCN_SWIFT_REGISTRY`. Move
just the binary out of `~/.local/share/shadcn-swift/` (e.g. copying it
alone into `/usr/local/bin`) and that auto-discovery breaks — symlink it
there instead if you want it on a different `PATH` entry, don't copy it.

Building from source instead — no extra step needed, since the built
binary sits inside the repo it was built from and finds the repo-root
`registry/` the same way:

```bash
git clone https://github.com/Vignesh-Thangamariappan/shadcn-swift.git && cd shadcn-swift
swift build -c release
export PATH="$PWD/.build/release:$PATH"   # add to your shell profile to persist
```

## 2. Wire up a consumer project (CLI)

From your app's repo root (wherever `Sources/` or your Xcode project lives):

```bash
shadcn-swift init
```

No `--registry` flag needed — it's found automatically per §1. This
writes `components.json` (tracks what's installed — don't hand-edit the
`installed` array) and creates `Sources/UI/`. See what's available:

```bash
shadcn-swift list
```

```
tokens
  Design tokens (color, spacing, radius, typography) exposed via SwiftUI Environment
button  (needs: tokens)
  6 variants (default/destructive/outline/secondary/ghost/link) x 4 sizes (sm/default/lg/icon)
card  (needs: tokens, button)
  Card container with optional trailing action button
context-menu  (needs: tokens, dropdown-menu)
  Themed wrapper over native .contextMenu, reusing dropdown-menu's item model
...
```

(47 components today, not all shown here — this list changes; `shadcn-swift
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

Pointing at a different registry (a fork, a local dev copy with
in-progress changes) is still `--registry <path>` on `init`/`list` — a
relative or absolute path, your choice. Whatever you pass is what lands
in `components.json`; a path relative to the consumer project (e.g.
`../shadcn-swift/registry/registry.json`) travels with a clone of that
project, an absolute one doesn't, so if you commit `components.json`,
know that an absolute `registryPath` is then machine-local unless every
clone has that registry at the same absolute path.

## 3. Wire up a consumer project (MCP / agent)

One line, for Claude Code:

```bash
claude mcp add shadcn-swift -- shadcn-swift-mcp
```

No `-e SHADCN_SWIFT_REGISTRY=...` needed — same auto-discovery as the CLI
(§1). For another MCP client, the equivalent of:

```json
{
  "mcpServers": {
    "shadcn-swift": {
      "command": "shadcn-swift-mcp"
    }
  }
}
```

(`command` needs either a bare name resolvable on `PATH`, as above, or an
absolute path if you haven't put `~/.local/share/shadcn-swift` on `PATH` —
either way, don't add an `env` block unless you're deliberately pointing
at a different registry than the one bundled alongside the binary.)

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

**How this actually compares to shadcn/ui's own MCP server** (checked
against their real source, not their marketing page — the two disagree):
shadcn's docs describe their MCP server as able to install components
"directly into your project," but its actual 7 tools
(`list_items_in_registries`, `search_items_in_registries`,
`view_items_in_registries`, `get_item_examples_from_registries`,
`get_add_command_for_items`, `get_audit_checklist`, `get_project_registries`)
are all read-only — none of them touch disk. `get_add_command_for_items`
hands back a CLI command STRING (e.g. `pnpm dlx shadcn@latest add
button`); a human or agent still has to run that separately for anything
to be written. Their own docs call the server "a bridge between your AI
assistant, component registries and the shadcn CLI" — discovery and
orchestration, with the CLI as the actual write mechanism. So shadcn's
real MCP is exactly as read-only as this one; it isn't a design choice
`shadcn-swift` made in departure from shadcn's own model, it's the same
choice, arrived at independently.

Where the two mechanisms differ: shadcn's `get_add_command_for_items`
hands the agent a *shell command to run*, and the shadcn CLI process that
command invokes does the actual writing outside the agent's own file
tools. `get_component` here hands the agent the actual file contents
directly, for the agent's own file-write tool to write — which is what
gives the agent's own diff/approval UI (Claude Code's file-write
confirmation, Cursor's inline diff, etc.) a chance to gate the change at
the content level. A shelled-out CLI invocation doesn't get that same
review for free.

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

`UI.Theme.Colors` mirrors real shadcn's stock token set: `primary`/
`primaryForeground`, `secondary`/`secondaryForeground`, `background`,
`foreground`, `border`, `destructive`, `card`/`cardForeground`, `popover`/
`popoverForeground`, `muted`/`mutedForeground`, `accent`/
`accentForeground`, `input`, `ring`. If you're customizing the theme,
match each token to the SURFACE it names (e.g. `popover` for popover/select/
combobox/tooltip content, `muted`/`mutedForeground` for skeleton fill and
secondary text) rather than reusing `background`/`primary` everywhere —
that's the exact conflation a parity audit against real shadcn caught and
fixed in this repo's own components.

### Button

Variants and sizes match real shadcn's stock `button.tsx` exactly:

```swift
UI.Button("Continue") {          // variant: .default, size: .default
    submit()
}

UI.Button("Delete", variant: .destructive) { delete() }
UI.Button("Cancel", variant: .outline) { dismiss() }
UI.Button("Cancel", variant: .secondary) { dismiss() }
UI.Button("Learn more", variant: .link) { openDocs() }
UI.Button(variant: .ghost, action: { showInfo() }) {
    Image(systemName: "info.circle")
}

UI.Button("Small", size: .sm) {}
UI.Button("Large", size: .lg) {}
UI.Button(size: .icon, action: { close() }) {
    Image(systemName: "xmark")
}
```

Buttons size to their content, same as real shadcn — they don't stretch to
fill their container by default. Wrap in `.frame(maxWidth: .infinity)`
yourself if you want that.

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
UI.Badge("Failed", variant: .destructive)
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

### Switch

The pill-and-sliding-thumb control (this repo called it `toggle` until a
parity audit against real shadcn caught the naming — shadcn's actual
`Toggle` is a different component, see below):

```swift
@State private var notificationsEnabled = true

UI.Switch("Notifications", isOn: $notificationsEnabled)
```

### Toggle

Real shadcn's Toggle: a pressable two-state button, the bold/italic
toolbar idiom — not a switch:

```swift
@State private var isBold = false

UI.Toggle(systemImage: "bold", isOn: $isBold)
UI.Toggle(systemImage: "italic", isOn: $isItalic, variant: .outline)
UI.Toggle(systemImage: "underline", isOn: $isUnderline, size: .sm)
```

### ToggleGroup

Several `UI.Toggle` sharing selection state — single (`Binding<Option>`) or
multiple (`Binding<Set<Option>>`):

```swift
@State private var alignment = "left"
@State private var textStyles: Set<String> = ["bold"]

UI.ToggleGroup(options: ["left", "center", "right"], selection: $alignment) {
    ["left": "text.alignleft", "center": "text.aligncenter", "right": "text.alignright"][$0]!
}

UI.ToggleGroup(options: ["bold", "italic", "underline"], selection: $textStyles) { $0 }
```

### Slider

```swift
@State private var volume = 0.6

UI.Slider(value: $volume)                     // 0...1 by default
UI.Slider(value: $rating, in: 0...5, step: 1)
```

### Spinner

```swift
UI.Spinner()            // 20pt default
UI.Spinner(size: 32)
```

### AspectRatio

A named passthrough over native `.aspectRatio(_:contentMode:)` — real
shadcn's own AspectRatio is the same kind of thin wrapper:

```swift
AsyncImage(url: thumbnailURL)
    .uiAspectRatio(16.0 / 9.0)
```

### Kbd

```swift
HStack(spacing: 4) {
    UI.Kbd("⌘")
    UI.Kbd("K")
}
```

### Collapsible

```swift
UI.Collapsible {
    Text("Advanced settings").font(.headline)
} content: {
    Text("Hidden until expanded.")
}
```

### Empty

```swift
UI.Empty(
    systemImage: "tray",
    title: "No messages",
    description: "New messages will show up here.",
    actionTitle: "Refresh",
    action: { refresh() }
)
```

### Breadcrumb

```swift
UI.Breadcrumb([
    UI.BreadcrumbItem("Home", action: { goHome() }),
    UI.BreadcrumbItem("Settings", action: { goToSettings() }),
    UI.BreadcrumbItem("Profile")   // last item: no action, current page
])
```

### InputOTP

```swift
@State private var code = ""

UI.InputOTP(length: 6, code: $code)
```

Backed by a real (near-invisible) `TextField`, so the system keyboard,
autofill, and SMS one-time-code suggestions all work normally — see the
deviation note in `input-otp/InputOTP.swift`.

### Field

Label + control + description-or-error as one unit. Generic over any
control — wraps `UI.Input` here, but works the same with `UI.TextArea`,
`UI.Select`, `UI.Checkbox`, or a bare SwiftUI control:

```swift
@State private var email = ""
@State private var password = ""

UI.Field("Email", description: "We'll never share your email.") {
    UI.Input("you@example.com", text: $email)
}

UI.Field("Password", error: "Password must be at least 8 characters.") {
    UI.Input("Password", text: $password, isSecure: true, isInvalid: true)
}
```

### Item

Generic list-row composition — leading content, title/subtitle, trailing
content, each independently optional via constrained convenience
initializers:

```swift
UI.Item("Plain row, no slots")

UI.Item("Notifications", subtitle: "Push, email, SMS", leading: {
    Image(systemName: "bell")
})

UI.Item("Wi-Fi", subtitle: "Connected", leading: {
    Image(systemName: "wifi")
}, trailing: {
    Image(systemName: "chevron.right").foregroundStyle(.secondary)
})
```

With only one slot, use the explicit `leading:`/`trailing:` label — a bare
trailing closure is ambiguous between the two single-slot initializers.

### InputGroup

`UI.Input` with a leading/trailing icon or button slot — same single-slot
gotcha as `Item` above:

```swift
@State private var search = ""
@State private var amount = ""

UI.InputGroup("Search", text: $search, leading: {
    Image(systemName: "magnifyingglass")
})

UI.InputGroup("0.00", text: $amount, trailing: {
    Button("Max") { amount = maxAmount }
})
```

### Accordion

Same items+content-closure shape as `UI.Tabs`. `allowsMultipleExpanded:
false` (the default, shadcn's "single" type) closes any other open section
when one opens; `true` (shadcn's "multiple") leaves them independent:

```swift
@State private var expanded: Set<String> = ["shipping"]

UI.Accordion(
    items: [
        (tag: "shipping", title: "Shipping"),
        (tag: "returns", title: "Returns")
    ],
    expanded: $expanded
) { tag in
    switch tag {
    case "shipping": Text("Ships in 3-5 business days.")
    default: Text("30-day returns, no questions asked.")
    }
}
```

### Pagination

```swift
@State private var page = 1

UI.Pagination(page: $page, totalPages: 42)
```

Beyond 7 pages, collapses to page 1, the last page, and a window around
the current page, with an ellipsis for the gap.

### Command

Modifier-shaped like `uiSheet`/`uiDialog` — a command palette is triggered
from anywhere (a toolbar button, a keyboard shortcut), not from one
specific view's own tap the way `UI.Combobox`'s trigger is self-contained:

```swift
@State private var showCommand = false

MyToolbarButton(action: { showCommand = true })
    .uiCommand(isPresented: $showCommand, groups: [
        UI.CommandGroup("Suggestions", items: [
            UI.CommandItem("New file", systemImage: "doc.badge.plus", shortcut: "⌘N", action: { newFile() }),
            UI.CommandItem("Search", systemImage: "magnifyingglass", shortcut: "⌘K", action: { search() })
        ]),
        UI.CommandGroup("Settings", items: [
            UI.CommandItem("Preferences", systemImage: "gearshape", action: { openSettings() })
        ])
    ])
```

### Calendar

Single-date selection, month-grid, locale-aware first weekday. An optional
predicate disables specific dates — here, weekends:

```swift
@State private var selectedDate: Date? = Date()

UI.Calendar(selection: $selectedDate) { date in
    Calendar.current.isDateInWeekend(date)
}
```

Range/multiple selection aren't supported yet — single date only. See the
`Foundation.Calendar` qualification note at the top of
`calendar/Calendar.swift` if you're editing this file: nearly every
internal helper needs Foundation's `Calendar` for month math, and an
unqualified `Calendar` reference inside `UI.Calendar`'s own body resolves
to itself, not Foundation's type (confirmed — it fails with `error: type
'UI.Calendar' has no member 'current'`, a loud compile error rather than a
silent wrong-behavior bug).

### DatePicker

Trigger button showing the formatted date, opens `UI.Calendar` in a
popover:

```swift
@State private var date: Date?

UI.DatePicker(selection: $date)
UI.DatePicker("Due date", selection: $date) { candidate in
    candidate < Date()   // disable past dates
}
```

### Carousel

```swift
@State private var page = 0

UI.Carousel(selection: $page, itemCount: images.count) { index in
    Image(images[index]).resizable().scaledToFill()
}
```

Pass `height:` if your pages aren't ~200pt tall — `TabView(.page)` needs a
concrete height, it doesn't measure per-page content.

### Table

Plain header row + body rows — no sort/filter/pagination (that's
`data-table`, not built; see the README). Row content is your own view,
same shape as `UI.Tabs`/`UI.Accordion`:

```swift
UI.Table(
    columns: [UI.TableColumn("Name"), UI.TableColumn("Status")],
    rowCount: people.count
) { index in
    HStack {
        Text(people[index].name).frame(maxWidth: .infinity, alignment: .leading)
        Text(people[index].status).frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

### Chart

Requires iOS 16+ (Swift Charts' own minimum). One flexible bar/line chart
over a single labeled series — see the README for why `import Charts` is
the one deliberate exception to this registry's package-free rule:

```swift
let data = [
    UI.ChartPoint("Mon", value: 12),
    UI.ChartPoint("Tue", value: 18),
    UI.ChartPoint("Wed", value: 9)
]

UI.Chart(data: data)               // bar, the default
UI.Chart(data: data, style: .line)
```

### Sidebar

Wraps native `NavigationSplitView` — a persistent nav rail on iPad's
regular width class, a normal push-navigation stack on iPhone's compact
width, both automatic:

```swift
@State private var selection: UI.SidebarItem.ID?

let items = [
    UI.SidebarItem("inbox", title: "Inbox", systemImage: "tray"),
    UI.SidebarItem("sent", title: "Sent", systemImage: "paperplane"),
    UI.SidebarItem("settings", title: "Settings", systemImage: "gearshape")
]

UI.Sidebar("Mail", items: items, selection: $selection) { selected in
    switch selected {
    case "inbox": InboxView()
    case "sent": SentView()
    case "settings": SettingsView()
    default: Text("Select an item").foregroundStyle(.secondary)
    }
}
```

Single-level navigation only — no nested/collapsible groups. See the
shadowing note at the top of `sidebar/Sidebar.swift` if you're adding a
new nav row type: this file sits alongside `UI.Label` (the `label`
component) in this registry, so `Label(_:systemImage:)` must stay
qualified `SwiftUI.Label`.

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
