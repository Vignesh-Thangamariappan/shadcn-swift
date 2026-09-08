# shadcn-swift

[![CI](https://github.com/Vignesh-Thangamariappan/shadcn-swift/actions/workflows/ci.yml/badge.svg)](https://github.com/Vignesh-Thangamariappan/shadcn-swift/actions/workflows/ci.yml)
[![Release](https://github.com/Vignesh-Thangamariappan/shadcn-swift/actions/workflows/release.yml/badge.svg)](https://github.com/Vignesh-Thangamariappan/shadcn-swift/actions/workflows/release.yml)
[![Latest release](https://img.shields.io/github/v/release/Vignesh-Thangamariappan/shadcn-swift)](https://github.com/Vignesh-Thangamariappan/shadcn-swift/releases/latest)
[![Swift 6.0](https://img.shields.io/badge/swift-6.0-orange.svg)](Package.swift)
[![MIT license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**shadcn/ui's model, ported to SwiftUI: own the component source, don't
`npm install` it.** 49 themeable SwiftUI components you copy into your
project — via a CLI or straight from your coding agent over MCP — and then
edit freely, because it's your code now, not a dependency.

## Try it in 60 seconds

```bash
mkdir -p ~/.local/share/shadcn-swift
curl -L https://github.com/Vignesh-Thangamariappan/shadcn-swift/releases/latest/download/shadcn-swift-macos-universal.tar.gz \
  | tar -xz -C ~/.local/share/shadcn-swift
echo 'export PATH="$HOME/.local/share/shadcn-swift:$PATH"' >> ~/.zshrc && source ~/.zshrc

cd /path/to/your/app
shadcn-swift init
shadcn-swift add card   # pulls in `button` + `tokens` too, dependencies first
```

You now have `Sources/UI/Card.swift`, `Sources/UI/Button.swift`, and a theme
file, sitting in your project as plain Swift — not a package dependency.
`UI.Card { ... }` and `UI.Button("Save") { ... }` are ready to use.

**Prefer handing this to a coding agent instead of running the CLI
yourself?** Register the MCP server once:

```bash
claude mcp add shadcn-swift -- shadcn-swift-mcp
```

Three read-only tools — `list_components`, `get_component`, `resolve_plan`
— let the agent discover and read components and resolve dependencies. No
write tool, on purpose: the agent reads, then writes to your project itself
using its normal file tools, so you always see and approve the diff.

Full walkthrough, every flag, and a real call site for all 49 components:
**[`docs/USAGE.md`](docs/USAGE.md)**.

## Why not just make an SPM package?

A package is exactly the thing shadcn/ui opted out of: one version to
negotiate, an API you can't touch, upstream churn you either take or fork.
This copies component source directly into your project instead — you own
it, edit freely, diff it, delete what you don't need.

| | SPM package | Copy-paste from shadcn.com by hand | shadcn-swift |
|---|---|---|---|
| You own the code | ❌ | ✅ | ✅ |
| Versioned dependency resolution | ✅ | ❌ | ✅ (`tokens` ← `button` ← `card`, etc.) |
| Agent-readable without writing to your repo | ❌ | ❌ | ✅ (MCP, read-only) |
| One command to add a component | ✅ | ❌ | ✅ |

## The one Swift-specific problem this had to solve

React scopes imports per file, so shadcn can call a component `Button` with
zero risk. Swift has no per-file import shadowing — a top-level `struct
Button` in your app module would shadow `SwiftUI.Button` **everywhere**,
silently changing every existing `Button(action:)` call site in your app.

Every component here is namespaced under a single `UI` enum instead
(`UI.Button`, `UI.Card`, ...), and every presentation modifier carries a
`ui` prefix for the same reason (`.uiSheet`, `.uiDialog`, ...). Types under
`UI`, modifiers under `ui` — that's the whole rule, and it composes cleanly
across separately-copied files. `Scripts/verify-components.sh` typechecks
this claim against the real iOS SDK on every change:

```swift
Button("plain SwiftUI button") {}   // SwiftUI's own
UI.Button("themed button") {}       // ours — no clash
```

Each component also ships its own `#if DEBUG` `#Preview` block, so opening
any file in Xcode shows that component's variants live in the canvas — the
equivalent of shadcn.com's per-component demo page, minus the website.

## What's in the box

**49 components**, zero third-party imports (one deliberate exception —
`chart` uses Apple's own first-party Swift Charts, which ships with the SDK
and adds no dependency):

| Category | Components |
|---|---|
| Foundations | `tokens`, `button`, `button-group`, `card`, `badge`, `label`, `separator`, `avatar`, `kbd` |
| Forms & input | `input`, `textarea`, `switch`, `toggle`, `checkbox`, `radio-group`, `slider`, `input-otp`, `field`, `input-group`, `select`, `combobox` |
| Feedback | `alert`, `progress`, `skeleton`, `spinner`, `empty`, `toast` |
| Navigation & disclosure | `tabs`, `accordion`, `collapsible`, `breadcrumb`, `pagination`, `sidebar` |
| Overlays | `sheet`, `dialog`, `confirmation-dialog`, `popover`, `tooltip`, `dropdown-menu`, `context-menu`, `command` |
| Data & media | `table`, `chart`, `calendar`, `date-picker`, `carousel`, `toggle-group`, `item`, `aspect-ratio` |

`calendar`, `date-picker`, `carousel`, `table`, and `chart` are the real
engineering-investment components here — built from scratch, not thin
wrappers (calendar is a full month-grid with locale-aware navigation; chart
wraps Swift Charts; carousel is native `TabView(.page)` for real swipe
physics). Every component's theme routes through a single injectable
`UI.Theme` (14 color tokens, spacing, radius, typography — override with
`.uiTheme(_:)`), the SwiftUI analog of Tailwind's CSS variables.

**Not built yet, on purpose:** `data-table` (sort/filter/column-visibility
state is a different scale of component than plain `table` — build it when
a real screen needs it), `drawer` (redundant with native `.sheet` on iOS),
and a small platform-gap bucket with no honest iOS equivalent
(`hover-card`, `navigation-menu`, `menubar`, `resizable`, `scroll-area`).
Full reasoning for every one of these, plus the complete parity audit
against real shadcn/ui and every shadowing hazard verified against the
compiler: **[`docs/STATUS.md`](docs/STATUS.md)**.

## Layout

```
registry/registry.json         component manifest: name, description, deps, per-platform file list
registry/swiftui/<name>/       vendored source for each component (copied into consumer projects — not built here)
Sources/ShadcnSwiftKit/        shared library: registry model + dependency resolution
Sources/ShadcnSwiftCLI/        the `shadcn-swift` CLI (init/list/add), built on ShadcnSwiftKit
Sources/ShadcnSwiftMCP/        the `shadcn-swift-mcp` read-only MCP server, built on ShadcnSwiftKit
Scripts/verify-components.sh   typechecks every registry/swiftui/**/*.swift + UsageProbe.swift against the iOS SDK
docs/USAGE.md                  walkthrough: wiring up a consumer project, then every component with call sites
docs/STATUS.md                 full engineering rationale: what's proven, what's skipped, and why
docs/SPEC.md                   the portable methodology, for porting this model to another language/framework
```

The registry is platform-keyed from day one (`"platforms": {"swiftui":
{...}, "compose": {...}}`), so a future Kotlin/Compose port means filling in
`compose` entries and a second CLI/MCP reading the same JSON — not a fork of
the registry. See [`docs/SPEC.md`](docs/SPEC.md).

## Installing from source

```bash
git clone https://github.com/Vignesh-Thangamariappan/shadcn-swift.git && cd shadcn-swift
swift build -c release
export PATH="$PWD/.build/release:$PATH"   # add to your shell profile to persist
```

Either way: keep the binaries next to the `registry/` directory they ship
beside (or, from source, inside the repo they were built in) — that's what
lets both tools auto-discover `registry.json` with no `--registry` flag or
`SHADCN_SWIFT_REGISTRY` env var. Point either one at a different
`registry.json` explicitly if you ever need to.

## License

MIT — see [`LICENSE`](LICENSE).
