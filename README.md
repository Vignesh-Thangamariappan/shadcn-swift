# shadcn-swift

shadcn/ui's model — own the code, don't `npm install` it — ported to SwiftUI,
with Kotlin/Compose planned as a second platform on the same registry.

You get the model two ways: a **CLI** you run by hand (`shadcn-swift add card`),
and a **read-only MCP server** that lets a coding agent (Claude Code, Cursor,
etc.) discover and read components without ever writing to your project itself.

**New to this repo? Start with [`docs/USAGE.md`](docs/USAGE.md)** — walks
through wiring up a consumer project both ways, then shows every component
that exists today with real call sites.

## Why not just make an SPM package?

A package is exactly the thing shadcn/ui opted out of: one version to
negotiate, an API you can't touch, upstream churn you either take or fork.
This copies component source directly into your project instead. You own it —
edit freely, diff it, delete what you don't need.

## The one Swift-specific problem this had to solve

React scopes imports per file, so shadcn can call a component `Button` with
zero risk. Swift has no per-file import shadowing: a top-level `struct Button`
in your app module would shadow `SwiftUI.Button` **everywhere**, silently
changing every existing `Button(action:)` call site in the app.

Every component here is namespaced under a single `UI` enum instead
(`UI.Button`, `UI.Card`, ...), and every presentation modifier (`.uiSheet`,
`.uiDialog`, ...) carries a `ui` prefix for the same reason — a bare
`.sheet`-named extension would risk overload ambiguity against the real
`.sheet(isPresented:)`. Types under `UI`, modifiers under `ui`: that's the
whole naming rule. It composes cleanly across separately-copied files (each
just extends `UI`) and sits at a call site next to a real `Button` with zero
ambiguity. That claim isn't just asserted — `Scripts/UsageProbe.swift` calls
both side by side, and `Scripts/verify-components.sh` typechecks it against
the real iOS SDK on every change:

```swift
Button("plain SwiftUI button") {}   // SwiftUI's own
UI.Button("themed button") {}       // ours — no clash
```

## Presentation references

Every component ships its own `#if DEBUG` / `#Preview` block, same convention
as EDS-iOS. Open any file under `registry/swiftui/` (or its vendored copy
under your project's `Sources/UI/`) in Xcode and the canvas shows that
component's variants live — the equivalent of shadcn.com's per-component demo
page, minus the website. `#if DEBUG` means none of it reaches a release
build. `Scripts/verify-components.sh` typechecks every preview with `-D
DEBUG` on each change, so a broken preview fails the same way a broken
component does.

## Layout

```
registry/registry.json         component manifest: name, description, deps, per-platform file list
registry/swiftui/<name>/       vendored source for each component (copied into consumer projects — not built here)
Sources/ShadcnSwiftKit/        shared library: registry model + dependency resolution
Sources/ShadcnSwiftCLI/        the `shadcn-swift` CLI (init/list/add), built on ShadcnSwiftKit
Sources/ShadcnSwiftMCP/        the `shadcn-swift-mcp` read-only MCP server, built on ShadcnSwiftKit
Scripts/verify-components.sh   typechecks every registry/swiftui/**/*.swift + UsageProbe.swift against the iOS SDK
docs/USAGE.md                  walkthrough: wiring up a consumer project, then every component with call sites
```

`ShadcnSwiftKit` exists so the CLI and the MCP server share one dependency
resolver instead of drifting into two implementations of `resolve()`.

The registry is platform-keyed from day one:

```json
"platforms": { "swiftui": { "files": [...] }, "compose": { "files": [...] } }
```

so adding Kotlin later means filling in `compose` entries and a second
CLI/MCP reading the same JSON — not a fork of the registry.

## Building

```bash
swift build -c release
cp .build/release/shadcn-swift .build/release/shadcn-swift-mcp /usr/local/bin/
```

(Or skip the copy and invoke `swift run shadcn-swift ...` / `swift run
shadcn-swift-mcp` from inside this repo — slower per-call, no install step.)

## Quick start

```bash
cd /path/to/your/app
shadcn-swift init --registry /path/to/shadcn-swift/registry/registry.json
shadcn-swift add card   # pulls tokens + button too, dependencies first
```

Or point a coding agent at it instead of running the CLI yourself — three
read-only MCP tools (`list_components`, `get_component`, `resolve_plan`, no
write tool on purpose):

```json
{
  "mcpServers": {
    "shadcn-swift": {
      "command": "/usr/local/bin/shadcn-swift-mcp",
      "env": { "SHADCN_SWIFT_REGISTRY": "/path/to/shadcn-swift/registry/registry.json" }
    }
  }
}
```

Full walkthrough, every flag, the agent's read-then-write flow, and a call
site for each component: **[`docs/USAGE.md`](docs/USAGE.md)**.

## What's here vs. what's next

**Here (proven):** registry schema, dependency resolution (`tokens` ←
`button` ← `card`, verified in `RegistryResolutionTests` and live over the
wire via `resolve_plan`), the `UI` namespace pattern, the CLI
(`init`/`add`/`list`), the MCP server (`list_components`/`get_component`/
`resolve_plan`, checked with a real stdio JSON-RPC round trip), and an
environment-injected `UI.Theme` standing in for Tailwind's CSS variables —
14 color tokens (`primary`/`primaryForeground`, `secondary`/
`secondaryForeground`, `background`, `foreground`, `border`, `destructive`,
`card`/`cardForeground`, `popover`/`popoverForeground`, `muted`/
`mutedForeground`, `accent`/`accentForeground`, `input`, `ring`), spacing,
radius, and typography — override via `.uiTheme(_:)`.

**26 components today.** 17 plain views: `tokens`, `button`, `card`, `badge`,
`input`, `switch`, `toggle`, `label`, `separator`, `avatar`, `progress`,
`skeleton`, `checkbox`, `radio-group`, `alert`, `textarea`, `tabs`. Plus the
overlay/portal wave — 3 more self-contained views whose own internal state
dissolves the portal problem (`select`, `dropdown-menu`, `combobox`), and 6
`ui`-prefixed presentation modifiers applied to a trigger view you already
have (`sheet`, `confirmation-dialog`, `dialog`, `popover`, `tooltip`,
`context-menu`). See [`docs/USAGE.md`](docs/USAGE.md) for a call site for
each. `Scripts/UsageProbe.swift` exercises all of them, several right next
to their real SwiftUI counterparts (`Button`, `Toggle`) or a same-named
SwiftUI type (`Alert`, `Label`), to keep proving the no-shadowing claim as
the set grows.

### Parity audit (verified against real shadcn, not memory)

A pass against `ui.shadcn.com` and a live shadcn install already vendored
elsewhere on this machine turned up real gaps, now fixed:

- **`switch` vs `toggle` were conflated.** What this repo originally shipped
  as `toggle` (pill + sliding thumb) is shadcn's `Switch`. Real shadcn's
  `Toggle` is an unrelated component — a pressable two-state button (the
  bold/italic toolbar idiom). Renamed the old component to `switch` and
  built a real `toggle` from scratch. **Breaking rename**, done deliberately
  pre-1.0 with no other consumers yet.
- **Button and Badge variant names/coverage didn't match stock shadcn.**
  Button is now `default | destructive | outline | secondary | ghost |
  link` × size `sm | default | lg | icon` (was `primary | secondary |
  ghost`, no size prop, and silently stretched to full width — real
  shadcn's Button is content-sized, not full-width, fixed too). Badge is
  now `default | secondary | destructive | outline` (was missing
  `destructive`, and `primary` where stock says `default`).
- **6 theme token pairs were missing**, collapsed into `background`/
  `secondary`/`primary` in a way that would've silently diverged the moment
  a theme got customized: `card`/`cardForeground`, `popover`/
  `popoverForeground`, `muted`/`mutedForeground`, `accent`/
  `accentForeground`, `input`, `ring`. Added, and routed the components
  that actually own those surfaces onto them (Card/Alert → `card`; Popover/
  Tooltip → `popover`; Skeleton fill, TextArea placeholder, Alert message →
  `muted`; pressed `UI.Toggle` → `accent`; Input/TextArea/Checkbox/
  RadioGroup/Select/Combobox borders → `input`; Input/TextArea focus rings
  → `ring`, not `primary`).

Two design calls worth knowing before you reach for these:
- **`dialog` uses `.fullScreenCover`**, not a custom `.overlay` scrim. The
  overlay version is the naive port and it's wrong in three specific ways —
  see the deviation note at the top of `dialog/Dialog.swift`.
- **`popover` and `tooltip` force `.presentationCompactAdaptation(.popover)`.**
  Without it, `.popover` silently degrades to a full sheet on iPhone's
  compact width — a runtime behavior difference a typecheck can't catch,
  since both forms compile fine.

**Not yet, coverage-wise** (the same parity audit's other finding — real
shadcn has ~50 registry items, we have 26): accordion, aspect-ratio,
breadcrumb, calendar, carousel, chart, collapsible, command, data-table,
date-picker, drawer, empty, field, input-group, input-otp, item, kbd,
menubar, navigation-menu, pagination, resizable, scroll-area, sidebar,
slider, spinner, table, toggle-group. None of these are half-built or
mismatched — they're simply not started. `hover-card` is the one exception:
deliberately skipped, not missing — iOS has no cursor-hover concept on a
touch device, so there's no honest port; `tooltip` (long-press) or
`popover` cover what it would have been used for.

**Not yet, otherwise:** a remote registry (today `--registry` /
`SHADCN_SWIFT_REGISTRY` are local paths), configurable namespace (the `UI`
name is currently baked into the vendored source, not templated), and
anything Kotlin/Compose.

**Invariant to keep, and to lint for once there are more components:** no
vendored file under `registry/swiftui/` may `import` anything but
`SwiftUI`/`Foundation`. The moment one needs a package, it's stopped being a
shadcn-style copy and become a dependency library instead.
