# Engineering status & rationale

The full "why" behind every deliberate decision, omission, and design call in
this repo — pulled out of [`README.md`](../README.md) so the top-level pitch
stays scannable. If you're deciding whether a component you need is here, or
whether a design call was deliberate vs. an oversight, this is the doc.

## What's here (proven)

Registry schema, dependency resolution (`tokens` ← `button` ← `card`,
verified in `RegistryResolutionTests` and live over the wire via
`resolve_plan`), the `UI` namespace pattern, the CLI (`init`/`add`/`list`),
the MCP server (`list_components`/`get_component`/`resolve_plan`, checked
with a real stdio JSON-RPC round trip), and an environment-injected
`UI.Theme` standing in for Tailwind's CSS variables — 19 color tokens
(`primary`/`primaryForeground`, `secondary`/`secondaryForeground`,
`background`, `foreground`, `border`, `destructive`/`destructiveForeground`,
`card`/`cardForeground`, `popover`/`popoverForeground`, `muted`/
`mutedForeground`, `accent`/`accentForeground`, `input`, `ring`) plus a
5-step `chartPalette`, all with real explicit light/dark values (not iOS
system dynamic colors), spacing, a 4-tier radius scale (`sm`/`md`/`lg`/
`xl`, plus a `.full` pill override any affected component can opt into),
a 4-tier typography scale, and stacked-layer shadows (`xs`/`sm`/`md`/`lg`)
matching Tailwind's real multi-box-shadow values — override the whole
theme via `.uiTheme(_:)`.

## The engineering-investment bucket

Four components needed real design work, not thin wrapping:

- **`calendar`** — a real month-grid built from scratch (leading/trailing
  blank cells, locale-aware first-weekday and weekday symbols, month
  navigation, a disabled-date predicate). It's also where the `UI`
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
- **`date-picker`** — exactly what it looks like once `calendar` exists:
  trigger button + a bare native `.popover` presenting `UI.Calendar` (not
  the `uiPopover` modifier: `UI.Calendar` already themes its own surface, so
  wrapping it in another themed popover container would double up
  backgrounds — same reasoning `UI.Combobox` uses for bypassing `uiSheet`).
- **`carousel`** — built on native `TabView(.page)` rather than a hand-rolled
  paging `ScrollView`, for real swipe/velocity/accessibility paging behavior.
  One real scope limit: `TabView(.page)` needs a concrete height (it doesn't
  measure per-page content), so `height` defaults to 200 and you pass your
  own if pages aren't that tall.
- **`table`** — shadcn's *plain* table: a styled header row + body rows, no
  sort/filter/pagination. `data-table` (TanStack-Table-backed upstream) is
  deliberately not built — see below.
- **`chart`** — the one deliberate exception to the "SwiftUI/Foundation
  only" import rule: it needs `import Charts`, Apple's own first-party
  framework. That's fine — Charts ships with the SDK and needs no package
  added to a consumer's project, so it doesn't reintroduce the "this is a
  dependency now" problem the rule exists to prevent, same as `import
  Foundation` never did. A third-party charting package would still violate
  the rule; this doesn't. `UI.Chart` hits the same enclosing-scope shadowing
  as `UI.Calendar`/`Foundation.Calendar` — verified too: dropping the
  qualifier fails differently here (`error: extra trailing closure passed in
  call`, since Swift tries `UI.Chart`'s own init instead) but it's the same
  story, a loud compile failure. Scope: one flexible bar/line chart over a
  single labeled series, not shadcn's full Recharts-backed family
  (multi-series, area, pie, tooltips) — extend `ChartStyle` in that file
  rather than adding chart-type-specific registry components.

**`sidebar` was reconsidered rather than skipped.** It was originally in the
platform-gap bucket ("doesn't map to iPhone"), but that's true of iPhone
specifically, not iOS/iPadOS as a whole — iPad's regular width class
genuinely supports a persistent nav rail. `UI.Sidebar` wraps native
`NavigationSplitView` rather than reimplementing collapse behavior by hand:
a persistent column on iPad, a normal push-navigation stack on iPhone's
compact width, both for free. Its shipped code has zero functional
dependency on `label` despite `Sidebar.swift`'s doc comment mentioning
`UI.Label` — that comment is a maintainer-facing warning (this registry's
own `verify-components.sh` typechecks all 49 files together, where the
collision is real), not a redistribution requirement, so `sidebar`'s only
registry dependency is `tokens`. Confirmed the hazard anyway, same rigor as
`UI.Calendar`/`UI.Chart`: a bare `Label(title, systemImage:)` inside
`UI.Sidebar`'s own body resolves to the enclosing `UI.Label` (single-
`String` init) instead of `SwiftUI.Label`, failing with `error: extra
argument 'systemImage' in call`. Scope: single-level navigation only —
shadcn's Sidebar also supports nested/collapsible groups, not built here.

`input-otp` is worth a callout: SwiftUI has no per-character-box text
input, so it uses the standard workaround — a real `TextField` at ~0.01
opacity sits under the visible digit boxes and actually captures keyboard
input, with `.allowsHitTesting(false)` on the boxes so a tap anywhere in the
row reaches the hidden field. See the deviation note in
`input-otp/InputOTP.swift`.

**`button-group` takes an explicit `[ButtonGroupItem]` array, not arbitrary
`@ViewBuilder` children.** Real shadcn's `ButtonGroup` is a generic `<div>`
that visually joins ANY children via sibling CSS selectors
(`[&>*:not(:first-child)]:rounded-l-none`, etc.) — SwiftUI has no equivalent
to "reach into arbitrary children and restyle them by position" without
`_VariadicView` (an underscore-prefixed, technically-private API this
registry avoids in vendored source). Same shape `UI.ToggleGroup` already
uses for the identical problem. `ButtonGroupText` (a static inline label)
and `ButtonGroupSeparator` (a manual cluster divider) aren't built — both
need mixed, arbitrary content, exactly the generality this approach
deliberately doesn't attempt. Corner-rounding and border-collapsing reuse
`UI.Button`'s own internal `buttonGroupPosition(_:orientation:)` and the
shared `UI.Theme.PartialBorderShape` — the same border-collapsing technique
`UI.Toggle` already proved, generalized to support real shadcn's
`vertical` orientation too (which `ToggleGroup` never needed).

**`toast` is the first component with a genuinely different shape.** Every
other component is a plain `View` or a presentation modifier tied to a
local `Binding`. A toast has to be fireable from ANYWHERE — a button's
`action` closure three views away from any toast UI — the same way real
`toast("message")` is a free function callable from anywhere in a shadcn
app, not a prop threaded down through the tree. `UI.ToastCenter` is a
single `@Observable` class, `Environment`-injected with a default instance
(a de facto app-wide singleton unless a screen explicitly overrides it via
`.environment(\.uiToastCenter, _:)`, e.g. for Previews wanting an isolated
queue). Mount `.uiToastHost()` once near the app root; call
`@Environment(\.uiToastCenter) var toast` anywhere else. Real shadcn's own
`sonner.tsx` is a thin theming wrapper around the external `sonner` npm
library, which owns the actual queue/positioning/dismiss behavior — there's
no equivalent third-party dependency to wrap, so this is a from-scratch
port of that same behavior. The four typed variants' colors
(`success`/`info`/`warning`/`error`) come from `sonner`'s OWN stylesheet
(fetched live from `emilkowalski/sonner`'s `src/styles.css`, light AND
dark blocks, HSL → sRGB converted by hand) — NOT from shadcn's own
`--popover` token, which real shadcn's wrapper only maps for the untyped
`default` toast. `toast.promise(...)` (an async loading→success/error
lifecycle helper) isn't ported — a Promise-chaining convenience with no
direct `async`/`await` analog worth forcing into this shape; call
`.show(variant: .loading)` then `.dismiss(id)` + a follow-up `.success(...)`
by hand instead. `.loading` itself IS ported (a real, standalone
`toast.loading(...)` call in real sonner, not only used internally by
`.promise`), using the existing `UI.Spinner`.

## Parity audit (verified against real shadcn, not memory)

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

## What's not built, and why

Real shadcn/ui's `new-york-v4` registry has 61 items as of this pass
(re-enumerated live via the GitHub API, not assumed from an earlier count —
it's grown since this repo's last full inventory, which is exactly why this
pass happened). This repo has 49. The gap breaks down into four honest
buckets: a naming difference, components already covered under a different
name, a deliberate non-build, a platform-gap bucket, and infrastructure
with no meaningful port — not a pile of unexamined missing items.

- **`alert-dialog` isn't missing — it's this repo's `confirmation-dialog`.**
  Same real shadcn component, renamed here for clarity (it wraps native
  `.confirmationDialog`, and "alert dialog" reads as a confusing name next
  to SwiftUI's own legacy `Alert` type). No functional gap.
- **`native-select` isn't missing either — this repo's `select` already IS
  the native-select equivalent.** Real shadcn ships two: a Radix-based
  `select.tsx` (a fully custom-rendered dropdown) and a `native-select.tsx`
  (a thin wrapper around the browser's own `<select>`). This repo's
  `UI.Select` wraps SwiftUI's native `Picker` — architecturally the
  `native-select` side of that split, not the custom-rendered one. There's
  no second component to build here.
- **`data-table`: deliberately not built**, not half-built. Sort state,
  filter state, column visibility, per-column custom renderers — a
  genuinely different scale of component from plain `table`. Build it when
  a real screen needs it, not speculatively.
- **`drawer`: not built because it's redundant with `sheet`.** shadcn's
  Drawer is a bottom-sheet-with-drag-handle (via the Vaul library) that
  also supports left/right/top anchoring. iOS's native `.sheet` already
  gives drag-indicator + detents — that's `uiSheet` — and side-anchored
  drawers aren't an idiomatic iOS pattern the way they are on web/desktop,
  so there's no distinct component to build here.
- **Platform-gap candidates, same call as `hover-card`:** `navigation-menu`/
  `menubar` (no persistent top-menu-bar paradigm on iOS), `resizable` (a
  mouse-drag concept), `scroll-area` (`ScrollView` already covers this with
  little to add). `hover-card` itself: deliberately skipped, not missing —
  iOS has no cursor-hover concept on a touch device, so there's no honest
  port; `tooltip` (long-press) or `popover` cover what it would have been
  used for.
- **`direction`: no port, no gap.** A pure RTL/LTR context provider
  (`DirectionProvider`, wrapping Radix's own) — SwiftUI already handles
  layout direction natively via the `layoutDirection` environment value,
  system-wide, with zero setup. Nothing to build.
- **`form`: no port, no gap.** shadcn's `form.tsx` is glue code for
  `react-hook-form` (`Controller`, `FormProvider`, `useFormContext`) — a
  specific JS form-state library integration, not a visual component.
  There's no equivalent library to integrate with in SwiftUI, and this
  repo's own `field` (see above) already covers the analogous
  label+control+description+error composition without needing one.
- **`marker` and the AI-chat family (`attachment`, `bubble`, `message`,
  `message-scroller`): deferred, not rejected.** `marker` is a small
  timeline/list-label decoration — plausible, low priority, no real screen
  has needed it yet. The chat family (message bubbles, attachment
  previews, auto-scrolling containers) is a specialized toolkit for
  building an actual chat/AI-assistant interface, not core UI most
  consumers of a general design system need — worth a dedicated pass if
  and when a real chat screen needs it, not spread thin across this one.

**Not yet, otherwise:** a remote registry (today `--registry` /
`SHADCN_SWIFT_REGISTRY` are local paths), configurable namespace (the `UI`
name is currently baked into the vendored source, not templated), and
anything Kotlin/Compose.

## Invariant to keep

No vendored file under `registry/swiftui/` may `import` a third-party
package. The moment one needs a package, it's stopped being a shadcn-style
copy and become a dependency library instead. `SwiftUI`/`Foundation` are
always fine; `chart/Chart.swift`'s `import Charts` is the one deliberate
exception on top of those — Apple's own first-party Swift Charts framework
ships with the SDK and needs nothing added to a consumer's project, so it
doesn't reintroduce the "this is a dependency now" problem the rule exists
to prevent. A third-party charting package would still violate this rule; a
zero-added-dependency system framework does not.
