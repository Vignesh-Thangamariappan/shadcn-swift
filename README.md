# shadcn-swift

shadcn/ui's model — own the code, don't `npm install` it — ported to SwiftUI, with
Kotlin/Compose planned as a second platform on the same registry.

## Why not just make an SPM package?

A package is exactly the thing shadcn/ui opted out of: one version to negotiate,
an API you can't touch, upstream churn you either take or fork. This copies
component source directly into your project instead. You own it — edit freely,
diff it, delete what you don't need.

## The one Swift-specific problem this had to solve

React scopes imports per file, so shadcn can call a component `Button` with zero
risk. Swift has no per-file import shadowing: a top-level `struct Button` in your
app module would shadow `SwiftUI.Button` **everywhere**, silently changing every
existing `Button(action:)` call site in the app.

Every component here is namespaced under a single `UI` enum instead
(`UI.Button`, `UI.Card`, ...). It composes cleanly across separately-copied
files (each just extends `UI`) and reads at the call site next to a real
`Button` with zero ambiguity — verified by typechecking both side by side, see
`UsageProbe` in the smoke test this repo was built with.

## Layout

```
registry/registry.json       component manifest: name, description, deps, per-platform file list
registry/swiftui/<name>/     vendored source for each component
Sources/ShadcnSwiftCLI/      the `shadcn-swift` CLI (Swift, ArgumentParser)
```

The registry is platform-keyed from day one:

```json
"platforms": { "swiftui": { "files": [...] }, "compose": { "files": [...] } }
```

so adding Kotlin later means filling in `compose` entries and a second CLI/build
step reading the same JSON — not a fork of the registry.

## Using it

```bash
swift build

cd /path/to/your/app
/path/to/shadcn-swift/.build/debug/shadcn-swift init \
  --registry /path/to/shadcn-swift/registry/registry.json

/path/to/shadcn-swift/.build/debug/shadcn-swift list --registry ...
/path/to/shadcn-swift/.build/debug/shadcn-swift add card   # pulls tokens + button too
```

`add` resolves the full dependency graph and copies dependencies before the
component that needs them, skips anything already installed (idempotent —
safe to run repeatedly), and tracks what's installed in a project-local
`components.json`, same idea as shadcn's.

## What's here vs. what's next

**Here (MVP, proven):** registry schema, dependency resolution
(`tokens` ← `button` ← `card`, verified in `RegistryResolutionTests`), the
`UI` namespace pattern, `init`/`add`/`list`, and an environment-injected
`UI.Theme` standing in for Tailwind's CSS variables (colors, spacing, radius,
typography — override via `.uiTheme(_:)`).

**Not yet:** a real component set beyond the three proof-of-concept pieces, a
remote registry (today `--registry` is a local path), configurable namespace
(the `UI` name is currently baked into the vendored source, not templated),
and anything Kotlin/Compose.

**Invariant to keep, and to lint for once there are more components:** no
vendored file may `import` anything but `SwiftUI`/`Foundation`. The moment one
needs a package, it's stopped being a shadcn-style copy and become a dependency
library instead.
