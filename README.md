# shadcn-swift

shadcn/ui's model — own the code, don't `npm install` it — ported to SwiftUI,
with Kotlin/Compose planned as a second platform on the same registry.

You get the model two ways: a **CLI** you run by hand (`shadcn-swift add card`),
and a **read-only MCP server** that lets a coding agent (Claude Code, Cursor,
etc.) discover and read components without ever writing to your project itself.

**New to this repo? Start with [`docs/USAGE.md`](docs/USAGE.md)** — walks
through wiring up a consumer project both ways, then shows every component
that exists today with real call sites. **Porting this model to a
different language/framework? Start with [`docs/SPEC.md`](docs/SPEC.md)**
instead — the parts of this model that generalize, extracted from what's
Swift-specific.

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

**47 components today.** 35 plain views: `tokens`, `button`, `card`,
`badge`, `input`, `switch`, `toggle`, `label`, `separator`, `avatar`,
`progress`, `skeleton`, `checkbox`, `radio-group`, `alert`, `textarea`,
`tabs`, `slider`, `spinner`, `kbd`, `collapsible`, `toggle-group`, `empty`,
`breadcrumb`, `input-otp`, `field`, `item`, `input-group`, `accordion`,
`pagination`, `calendar`, `carousel`, `table`, `chart`, `sidebar`, plus the
passthrough `aspect-ratio` modifier. Plus the overlay/portal wave — 5 more
self-contained views whose own internal state dissolves the portal problem
(`select`, `dropdown-menu`, `combobox`, `command`, `date-picker`), and 6
`ui`-prefixed presentation modifiers applied to a
trigger view you already have (`sheet`, `confirmation-dialog`, `dialog`,
`popover`, `tooltip`, `context-menu`). See [`docs/USAGE.md`](docs/USAGE.md)
for a call site for each. `Scripts/UsageProbe.swift` exercises all of them,
several right next to their real SwiftUI counterparts (`Button`, `Toggle`,
`Slider`) or a same-named SwiftUI type (`Alert`, `Label`), to keep proving
the no-shadowing claim as the set grows.

`field`, `item`, and `input-group` close the form-composition gap the
coverage list used to flag: building a real form no longer means manually
wiring `label` + `input` + an error `Text` at every call site — `UI.Field`
does that, generic over any control. Two of the six wrap-a-control
components (`item`, `input-group`) needed a same-shape gotcha documented
in their files: a single-slot convenience initializer (`leading:` only, or
`trailing:` only) is ambiguous as a bare trailing closure — the compiler
can't tell which slot you mean without an explicit argument label.

**`calendar` is the first "genuine engineering investment" component** —
a real month-grid built from scratch (leading/trailing blank cells,
locale-aware first-weekday and weekday symbols, month navigation, a
disabled-date predicate), not a thin wrapper. It's also where the `UI`
namespace's central bet gets stress-tested hardest: `UI.Calendar`'s own
implementation needs Foundation's `Calendar` for month math constantly, so
nearly every internal helper writes `Foundation.Calendar` explicitly — the
same enclosing-scope-wins rule that requires `SwiftUI.Button` inside
`UI.Button`, just far more pervasive here. Verified this actually bites,
not just asserted: dropping one qualifier produces `error: type
'UI.Calendar' has no member 'current'` — a loud compile failure, not
`UI.Button`'s quieter "compiles fine, means something else." Single-date
selection only for now; shadcn's Calendar (via react-day-picker) also
supports multiple/range modes, not built here.

**The rest of the engineering-investment bucket is done: `date-picker`,
`carousel`, `table`, `chart`.**
- `date-picker` is exactly what it looks like once `calendar` exists —
  trigger button + a bare native `.popover` presenting `UI.Calendar`
  (not the `uiPopover` modifier: `UI.Calendar` already themes its own
  surface, so wrapping it in another themed popover container would
  double up backgrounds — same reasoning `UI.Combobox` uses for bypassing
  `uiSheet`).
- `carousel` is built on native `TabView(.page)` rather than a hand-rolled
  paging `ScrollView` — real swipe/velocity/accessibility paging behavior
  for free. One real scope limit: `TabView(.page)` needs a concrete height
  (it doesn't measure per-page content), so `height` defaults to 200 and
  you pass your own if pages aren't that tall.
- `table` is shadcn's PLAIN table — a styled header row + body rows, no
  sort/filter/pagination. `data-table` (TanStack-Table-backed upstream) is
  deliberately NOT built: it's sort state, filter state, column
  visibility, per-column custom renderers — a genuinely different scale
  of component that deserves its own design pass when a real screen needs
  it, not a half-built version bolted onto `table`.
- `chart` is the one deliberate exception to the "SwiftUI/Foundation only"
  import rule below — it needs `import Charts`, Apple's own first-party
  framework. That's fine: Charts ships with the SDK and needs no package
  added to a consumer's project, so it doesn't reintroduce the "this is a
  dependency now" problem the rule exists to prevent, same as
  `import Foundation` never did. A third-party charting package would
  still violate the rule; this doesn't. `UI.Chart` hits the same
  enclosing-scope shadowing as `UI.Calendar`/`Foundation.Calendar` (this
  type is `UI.Chart`, Charts' own view is `Charts.Chart`) — verified that
  too: dropping the qualifier fails differently here (`error: extra
  trailing closure passed in call`, since Swift tries `UI.Chart`'s own
  init instead) but it's the same story, a loud compile failure. Scope:
  one flexible bar/line chart over a single labeled series, not shadcn's
  full Recharts-backed family (multi-series, area, pie, tooltips) —
  extend `ChartStyle` in that file rather than adding chart-type-specific
  registry components.

**`sidebar` was reconsidered rather than skipped.** It was originally in
the platform-gap bucket ("doesn't map to iPhone"), but that's true of
iPhone specifically, not iOS/iPadOS as a whole — iPad's regular width
class genuinely supports a persistent nav rail. `UI.Sidebar` wraps native
`NavigationSplitView` rather than reimplementing collapse behavior by
hand: a persistent column on iPad, a normal push-navigation stack on
iPhone's compact width, both for free. Its shipped code has zero
functional dependency on `label` despite `Sidebar.swift`'s doc comment
mentioning `UI.Label` — that comment is a maintainer-facing warning (this
registry's own `verify-components.sh` typechecks all 47 files together,
where the collision is real), not a redistribution requirement, so
`sidebar`'s only registry dependency is `tokens`. Confirmed the hazard
anyway, same rigor as `UI.Calendar`/`UI.Chart`: a bare `Label(title,
systemImage:)` inside `UI.Sidebar`'s own body resolves to the enclosing
`UI.Label` (single-`String` init) instead of `SwiftUI.Label`, failing with
`error: extra argument 'systemImage' in call`. Scope: single-level
navigation only — shadcn's Sidebar also supports nested/collapsible
groups, not built here.

`input-otp` is worth a callout: SwiftUI has no per-character-box text
input, so it uses the standard workaround — a real `TextField` at ~0.01
opacity sits under the visible digit boxes and actually captures keyboard
input, with `.allowsHitTesting(false)` on the boxes so a tap anywhere in the
row reaches the hidden field. See the deviation note in
`input-otp/InputOTP.swift`.

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

**The engineering-investment bucket is done** (`calendar`, `date-picker`,
`carousel`, `table`, `chart`) and so is the composition-primitives bucket
(`field`, `item`, `input-group`, `accordion`, `pagination`, `command`).
Real shadcn has ~50 registry items, we have 46 — what's left is down to
one deliberate non-build and a platform-gap bucket:

- **`data-table`: deliberately not built**, not half-built. Sort state,
  filter state, column visibility, per-column custom renderers — a
  genuinely different scale of component from plain `table`. Build it
  when a real screen needs it, not speculatively.
- **`drawer`: not built because it's redundant with `sheet`.** shadcn's
  Drawer is a bottom-sheet-with-drag-handle (via the Vaul library) that
  also supports left/right/top anchoring. iOS's native `.sheet` already
  gives drag-indicator + detents — that's `uiSheet` — and side-anchored
  drawers aren't an idiomatic iOS pattern the way they are on web/desktop,
  so there's no distinct component to build here.
- **Platform-gap candidates, same call as `hover-card`:**
  `navigation-menu`/`menubar` (no persistent top-menu-bar paradigm on
  iOS), `resizable` (a mouse-drag concept), `scroll-area` (`ScrollView`
  already covers this with little to add). `hover-card` itself:
  deliberately skipped, not missing — iOS has no
cursor-hover concept on a touch device, so there's no honest port;
`tooltip` (long-press) or `popover` cover what it would have been used for.

**Not yet, otherwise:** a remote registry (today `--registry` /
`SHADCN_SWIFT_REGISTRY` are local paths), configurable namespace (the `UI`
name is currently baked into the vendored source, not templated), and
anything Kotlin/Compose.

**Invariant to keep, and to lint for once there are more components:** no
vendored file under `registry/swiftui/` may `import` a third-party
package. The moment one needs a package, it's stopped being a shadcn-style
copy and become a dependency library instead. `SwiftUI`/`Foundation` are
always fine; `chart/Chart.swift`'s `import Charts` is the one deliberate
exception on top of those — Apple's own first-party Swift Charts
framework ships with the SDK and needs nothing added to a consumer's
project, so it doesn't reintroduce the "this is a dependency now" problem
the rule exists to prevent. A third-party charting package would still
violate this rule; a zero-added-dependency system framework does not.
