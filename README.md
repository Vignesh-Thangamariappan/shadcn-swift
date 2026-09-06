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
(`UI.Button`, `UI.Card`, ...). It composes cleanly across separately-copied
files (each just extends `UI`) and sits at a call site next to a real `Button`
with zero ambiguity. That claim isn't just asserted — `Scripts/UsageProbe.swift`
calls both side by side, and `Scripts/verify-components.sh` typechecks it
against the real iOS SDK on every change:

```swift
Button("plain SwiftUI button") {}   // SwiftUI's own
UI.Button("themed button") {}       // ours — no clash
```

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

## CLI usage

```bash
cd /path/to/your/app
shadcn-swift init --registry /path/to/shadcn-swift/registry/registry.json
shadcn-swift list --registry /path/to/shadcn-swift/registry/registry.json
shadcn-swift add card   # pulls tokens + button too — see dependency resolution below
```

`add` resolves the full dependency graph and copies dependencies before the
component that needs them, skips anything already installed (idempotent —
safe to run repeatedly, `--force` to re-copy), and tracks what's installed in
a project-local `components.json`, same idea as shadcn's.

`init --registry` accepts a relative or absolute path; whatever you pass is
what lands in `components.json`. A path relative to the consumer project
(e.g. `../shadcn-swift/registry/registry.json`) travels with a clone of that
project — an absolute path (as in the examples above) does not, so if you
commit `components.json`, know that the `registryPath` field is then
machine-local unless every clone has this repo at the same absolute path.

## MCP server

`shadcn-swift-mcp` exposes three tools, and deliberately **no write tool**:

| Tool | Does |
|---|---|
| `list_components` | Every component: name, description, dependencies, platforms |
| `get_component` | One component's own source file(s), with full contents |
| `resolve_plan` | Transitive dependency order for a set of names, dependencies first |

The point of the vendored model is that a human reviews what lands in their
project, and a component they've hand-edited must never get silently
clobbered by an agent's tool call — so writing stays with `shadcn-swift add`,
typed by hand. An agent's flow is: `resolve_plan(["card"])` →
`get_component` for each name in that order → write the files itself (with
your review), the same way it would write any other code.

Point it at a registry via the `SHADCN_SWIFT_REGISTRY` environment variable
(path to `registry.json`). Register it (e.g. in a project's `.mcp.json`):

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

## What's here vs. what's next

**Here (proven):** registry schema, dependency resolution (`tokens` ←
`button` ← `card`, verified in `RegistryResolutionTests` and live over the
wire via `resolve_plan`), the `UI` namespace pattern, the CLI
(`init`/`add`/`list`), the MCP server (`list_components`/`get_component`/
`resolve_plan`, checked with a real stdio JSON-RPC round trip), and an
environment-injected `UI.Theme` standing in for Tailwind's CSS variables
(colors, spacing, radius, typography, plus a `destructive` color — override
via `.uiTheme(_:)`).

**Six components today:** `tokens`, `button`, `card`, `badge`, `input`
(styled `TextField`/`SecureField` with a focus ring and an invalid/error
state), `toggle` (custom `ToggleStyle`, not `.tint()`). See
[`docs/USAGE.md`](docs/USAGE.md) for call sites. `Scripts/UsageProbe.swift`
exercises all of them side by side with their real SwiftUI counterparts
(`Button`, `Toggle`) to keep proving the no-shadowing claim as the set grows.

**Not yet:** a bigger component set (dialog/sheet, select, alert — these are
presentation modifiers, not plain views, so they need a registry-shape
decision before copying the current pattern), a remote registry (today
`--registry` / `SHADCN_SWIFT_REGISTRY` are local paths), configurable
namespace (the `UI` name is currently baked into the vendored source, not
templated), and anything Kotlin/Compose.

**Invariant to keep, and to lint for once there are more components:** no
vendored file under `registry/swiftui/` may `import` anything but
`SwiftUI`/`Foundation`. The moment one needs a package, it's stopped being a
shadcn-style copy and become a dependency library instead.
