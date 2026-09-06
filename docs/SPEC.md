# The shadcn-for-X model: a portable spec

`shadcn-swift` is one implementation of a model that isn't actually
Swift-specific. This document extracts the parts that generalize — so a
future `shadcn-kotlin` (Jetpack Compose), or any other language/UI
framework, can follow the same methodology instead of re-deriving it from
this repo's git history. Everything Swift-specific (exact token names, the
`UI` namespace, `ui`-prefixed modifiers) lives in the main
[`README.md`](../README.md) and [`USAGE.md`](USAGE.md) — this document is
about the decisions behind those choices, phrased so they transfer.

If you're porting this model to a new target, read this document, then
treat `registry/swiftui/` as a worked example of applying it — not as a
template to translate line-by-line.

## 1. The core philosophy (language-independent)

Own the code, don't depend on it. A component registry ships source files,
not a package. A CLI (and optionally an MCP server) copies those files
into a consumer's project on request, resolving dependencies first. The
consumer can then edit, diff, or delete what lands — same as if they'd
hand-written it. This is true regardless of target language: the model is
about *distribution*, not about any particular language's syntax.

The registry itself (`registry.json` in this repo) is already
language-agnostic:

```json
{
  "version": 1,
  "components": [
    {
      "name": "button",
      "description": "...",
      "dependencies": ["tokens"],
      "platforms": {
        "swiftui": { "files": ["Button.swift"] },
        "compose": { "files": ["Button.kt"] }
      }
    }
  ]
}
```

Adding a new target language means adding a new key under `platforms` and
a sibling `registry/<platform>/` directory — not a new registry format,
not a second manifest to keep in sync. `ShadcnSwiftKit`'s
`Registry`/`resolve()` types don't know or care what's inside a
component's files; a Kotlin CLI/MCP pair can be a straight port of that
same resolver, or a fresh implementation in Kotlin itself — the algorithm
(§4) is what has to match, not the code.

## 2. The question every new target must answer first

**Does the target language scope imports per file, or per module/package?**

This is the single question that determines whether any of the namespace
machinery below is needed at all.

- **Per-file scoping (e.g. JavaScript/TypeScript, most scripting
  languages):** a local `Button` in one file never affects a `Button`
  imported in another file. shadcn/ui itself relies on exactly this — it
  can call a component `Button` with zero collision risk. **If your
  target works this way, skip straight to §5 — you don't need a namespace
  strategy at all.**
- **Per-module/package scoping (e.g. Swift, Kotlin, Java, C#):** a
  top-level declaration is visible throughout the whole compilation unit
  once compiled together, not just the file that declares it. A vendored
  `struct Button` collides with the framework's own `Button` everywhere
  in the app, not just locally — silently, if the language lets the
  narrower declaration win over an import (§3 explains why this is worse
  than a normal "duplicate symbol" error). **This is the case that forced
  every decision from here on** — verify it's actually true for your
  target with a real two-file compile test before assuming it, the same
  way this repo verified it for Swift (see `Scripts/verify-components.sh`
  and the throwaway shadowing tests referenced in the git history for
  `UI.Calendar`, `UI.Chart`, `UI.Sidebar`).

## 3. If your target has per-module scoping: the namespace decision

Two defensible strategies, in order of preference:

1. **An enclosing namespace type** (this repo's choice: `enum UI { struct
   Button ... }`, called as `UI.Button`). Works when the target language
   has real nested-type support and idiomatic call-site dot-access. Keeps
   shadcn's naming ergonomics (`Button`, not `DSButton` or `SButton`)
   without stutter.
2. **A prefix** (`DSButton`, `UIButton`-with-your-own-prefix). Fall back to
   this only if the target language's nested types are awkward to declare
   across separately-copied files, or if dot-access namespacing isn't
   idiomatic there.

Whichever you pick, **the enclosing-scope-wins hazard doesn't stop at
component names that don't already exist in the framework.** The sharpest
version of this bug is a component whose name matches a type the
*standard library or UI framework itself* uses constantly — this repo's
`UI.Calendar` needs `Foundation.Calendar` for month arithmetic in nearly
every internal method, and `UI.Chart` needs `Charts.Chart` the same way.
Inside such a component's own implementation, an unqualified reference to
the standard type resolves to the enclosing namespace type instead — not
a hypothetical, verified for Swift by literally stripping the
qualification and confirming the compiler error (see the deviation notes
in `calendar/Calendar.swift`, `chart/Chart.swift`, `sidebar/Sidebar.swift`).
**Run the equivalent experiment for your target language before trusting
that qualification is even necessary there** — don't assume Swift's
lexical-scope-before-import rule holds elsewhere; verify it.

The fix, once confirmed: always fully qualify the standard/framework type
inside the vendored file's own implementation (`Foundation.Calendar`,
never bare `Calendar`, inside `UI.Calendar`'s body). Document it loudly in
the file — this is exactly the kind of thing a future editor "cleans up"
by mistake if it isn't explained.

## 4. Dependency resolution (language-independent)

A component may declare `dependencies: [...]` naming other component
names in the same registry. Resolving `add X` means: **visit
dependencies before the component that needs them, each component exactly
once, in the order first encountered.** In pseudocode:

```
resolve(names):
    seen = {}
    ordered = []
    visit(name):
        if name in seen: return
        component = lookup(name)  // error if missing
        seen.add(name)
        for dep in component.dependencies:
            visit(dep)
        ordered.append(component)
    for name in names:
        visit(name)
    return ordered
```

This is the whole algorithm — a depth-first post-order traversal, cycle-
free by construction as long as the registry itself has no dependency
cycles (worth a lint, not handled specially here). It has nothing to do
with the target language; port it verbatim. This repo's test for it
(`RegistryResolutionTests`) is a good template: assert that a
multi-level chain resolves dependencies-first, and that a component
depended on by two different requested components appears only once.

## 5. Component classification — a checklist for every new component

Before writing a component's source, classify it. This determines its
shape, independent of language:

1. **Plain view/composable.** The common case — a self-contained unit of
   UI taking props/parameters, no special presentation concerns. Most of
   shadcn's own components, and most of this registry, are this.
2. **Self-contained view owning its own presentation state internally**
   (this registry's `select`, `dropdown-menu`, `combobox`, `command`,
   `date-picker`). Use this whenever the UI framework already provides a
   native mechanism for the overlay/menu/popover in question — the
   component just owns a private state flag and calls that native
   mechanism itself. The caller never sees the presentation machinery.
   This is usually the RIGHT default once you notice the framework has
   the native primitive; don't reach for shape 3 out of habit.
3. **Modifier/wrapper applied to existing content via caller-owned
   external state** (this registry's `ui`-prefixed `sheet`, `dialog`,
   `popover`, `confirmation-dialog`). Reach for this only when the
   presentation is inherently triggered from *outside* the component
   itself — a toolbar button opening a command palette, a delete button
   opening a confirmation — and the framework's own presentation API
   takes a binding/observable flag rather than being self-triggered.
   **A component that needs this shape is where the "no per-file import
   scoping" problem in §2 would show up as a REAL blocking issue if your
   namespace strategy used a prefix on the wrapped-content type itself
   rather than on the wrapper function/modifier name** — verify your
   naming convention covers this shape specifically, it's easy to design
   a namespace strategy that only covers shape 1/2 and then discover
   shape 3 needs its own rule.
4. **Gesture-driven, no bindable state** (this registry's `tooltip`,
   `context-menu` — triggered by a long-press with no external
   Binding/observable at all). These often can't be driven open
   programmatically from a reference/preview harness — that's a real,
   documented limitation, not a bug to fix.
5. **Deliberately not built.** Two different reasons, and they read
   differently to a user of the registry — don't conflate them:
   - **Platform gap**: the source design has no honest equivalent on this
     target (this registry's `hover-card` — no cursor-hover concept on a
     touch device). State the missing platform primitive plainly.
     `navigation-menu`/`menubar`/`sidebar`(on phone-shaped form factors)/
     `resizable`/`scroll-area` are this repo's other examples.
   - **Scope boundary**: the component is buildable but is a genuinely
     different *scale* of engineering from its siblings (this registry's
     `data-table` vs. plain `table` — sort/filter/column-visibility state
     is a different kind of component, not a bigger version of the same
     one). Don't half-build it to check a box; build it properly when a
     real screen needs it, and say so.

   Reconsider a "platform gap" call when your target has more than one
   real device/form-factor idiom — this repo's `sidebar` was in the
   platform-gap bucket ("doesn't map to iPhone") before being rebuilt
   specifically for the tablet-class form factor once that distinction
   was made explicit. The lesson: "platform gap" claims are about a
   *specific* device idiom, not the whole target platform — check whether
   the target has multiple idioms (phone vs. tablet, mobile vs. desktop)
   before writing off a component for all of them.

## 6. CLI responsibilities (language-independent shape)

- `init`: write a project-local config recording the registry location
  and a destination directory. Don't overwrite an existing config.
- `list`: read the registry, print name/description/dependencies. Pure
  read, no state.
- `add <names...>`: resolve dependencies (§4), copy each component's
  files into `<destination>/<component-name>/`, skip anything already
  recorded as installed (idempotent by default — re-running `add` after
  a partial failure or from a script must be a no-op, not a duplicate
  copy or an error), `--force` to override. Update the installed list
  only for components newly copied.

None of this cares what language the copied files are in — a Kotlin CLI
for `shadcn-kotlin` can be nearly a transliteration of
`Sources/ShadcnSwiftCLI/AddCommand.swift`.

## 7. MCP server responsibilities, and the one rule that isn't optional

Three read-only tools cover the whole surface a coding agent needs:
- **list**: every component's name/description/dependencies/platforms.
- **get**: one component's own files, full contents, for a given
  platform. Does NOT include dependency files — that's what resolve is
  for.
- **resolve**: the transitive dependency order for a set of names,
  dependencies first (§4, served over the wire).

**There is no write tool, and there shouldn't be one.** The entire model
depends on a human (or the CLI they typed) reviewing what lands in their
project, and a component they've hand-edited must never get silently
clobbered by an agent's tool call. An agent's flow is: resolve → get each
name in that order → write the files itself, through its own normal
file-write tool, with the same review step a human typing the CLI command
gets. This rule doesn't vary by target language or by how capable the
agent is — it's a property of the *distribution model*, not an
implementation detail to relax once tooling improves.

## 8. Verification discipline

Registry files are deliberately outside the CLI/MCP tool's own build
graph — they're vendored TO other projects, not built as part of this
one. That means the tool's own test suite passing tells you nothing about
whether the registry's *source* actually compiles. Two checks, both
target-agnostic in spirit:

- **Typecheck/compile every registry file against the real target
  compiler and SDK**, not just via whatever internal build system the
  CLI/MCP happens to use. This repo's `Scripts/verify-components.sh` does
  this directly against Xcode's SDK for exactly this reason — a registry
  file that only compiles as part of some internal package but not
  against the real target toolchain is a latent bug for every consumer.
- **Confirm a fresh `add` into a scratch consumer project also compiles
  standalone**, independent of this repo's own source tree. This is what
  actually simulates what a real consumer experiences, and it's caught
  real bugs here that the registry-only typecheck didn't (files that
  compile fine sitting next to their siblings in this repo, but only
  because a sibling component happened to also be present — see the
  `sidebar`/`label` coexistence check in this repo's commit history).

If the target UI framework has a live-preview/canvas mechanism (Xcode's
`#Preview` for SwiftUI; Jetpack Compose's `@Preview` is a near-exact
counterpart), give every component one, gated so it never reaches a
release build (`#if DEBUG` here). It ships with the vendored file, so a
consumer gets a working reference the moment they run `add` — no separate
demo app, no docs site. Document honestly which components *can't* be
driven open in a static preview (shape 4 in §5) rather than faking it.

## 9. The "no dependency" invariant, and its one legitimate exception

No registry file may import a third-party package. That's the whole rule
— it's what keeps this a copy-paste model instead of a dependency
manager in disguise. The exception is narrower than "well-known" or
"popular": a **first-party framework that ships with the target platform's
SDK and requires zero addition to a consumer's project** (this repo's
`chart/Chart.swift` needs `import Charts`, Apple's own framework) doesn't
reintroduce the problem the rule exists to prevent, the same way
importing the target language's own standard library never did. A
third-party charting library would still violate the rule; Charts
doesn't, because nothing needs to be added anywhere for it to resolve.
State this exception explicitly in whatever document carries your
target's version of this invariant — don't let it become an implicit,
undocumented crack.

## 10. What NOT to port

- **Specific token names and values** — `card`/`popover`/`muted`/`accent`/
  `input`/`ring` are shadcn's actual stock theme vocabulary (verified
  against a live shadcn install, not invented) and transfer as concepts,
  but the concrete SwiftUI `Color` values chosen for them are Swift/iOS
  presentation choices, not part of the model.
- **The specific namespace/prefix strings** (`UI`, `ui`) — pick whatever
  reads idiomatically in the target language; the requirement is
  consistency and collision-avoidance, not these exact tokens.
- **Any single component's internal implementation choices** — e.g. this
  repo's `UI.Switch` using a hand-drawn `ToggleStyle` instead of
  `.tint()`, or `UI.Carousel`'s fixed-height limitation. These are
  Swift/SwiftUI-API-specific engineering calls; a new target should make
  its own equivalent calls after investigating its own framework's
  quirks, not copy these ones by assumption.
