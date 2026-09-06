---
name: shadcn parity drift
icon: 🎨
description: Flags new upstream shadcn components and variant/token drift on the components we've already ported.
trigger: weekly on monday at 09:00
permission: read-only
severity-floor: info
auto-run: true
---

Check this repo (a from-scratch SwiftUI port of shadcn/ui's component
model) for drift against real, current shadcn/ui. Two checks:

**1. New upstream components.** Fetch shadcn/ui's current registry —
https://ui.shadcn.com/docs/components lists every item, or check
github.com/shadcn-ui/ui directly if that page doesn't load cleanly. Diff
that list against the `name` fields in `registry/registry.json` here.
Flag any shadcn component that exists upstream and isn't in our registry
at all.

Do NOT flag these — they're deliberate, documented decisions, not gaps:
- `hover-card`, `navigation-menu`, `menubar`, `resizable`, `scroll-area` —
  platform-gap skips, explained in README.md's "Not yet" section.
- `data-table`, `drawer` — deliberately not built (data-table is a
  different scale of component from `table`; drawer is redundant with
  `sheet` on iOS). Also explained in README.md.
- shadcn's newer "AI chat" family (Attachment, Bubble, Marker, Message,
  Message Scroller, Questionnaire) — a conversational-UI-specific
  sub-family, out of scope unless the project starts building a chat
  surface.
- Direction and Typography — these are a utility and a CSS system
  respectively, not discrete components.

**2. Variant/token drift on components we HAVE built.** These five have a
known history of upstream drift (a prior audit found real mismatches
here, since fixed): `button`, `badge`, `alert`, `switch`, `toggle`.
Fetch the live shadcn source for these as ground truth — prefer
`~/Documents/Github/Repos/adaptiveu-v2/frontend/src/components/ui/{button,badge,alert}.tsx`
if that repo and those files exist locally (it's an actual current shadcn
install, more reliable than prose docs); fall back to
https://ui.shadcn.com/docs/components/<name> otherwise. Compare their
`cva()` variant/size literal lists against what's declared in this repo's
`registry/swiftui/<name>/*.swift` (e.g. `enum ButtonVariant { case ... }`,
`enum ButtonSize { case ... }`). Flag any variant or size shadcn has that
we don't, any name mismatch, or anything we have that shadcn has since
removed. Note: `switch` here is shadcn's `Switch`, and `toggle` is
shadcn's `Toggle` (a pressable two-state button, not a switch) — check
each against its correctly-named shadcn counterpart, not each other.

Report as a punch list: what's new upstream (component names only, no
need to fully spec each one), and what's drifted (component name, the
specific mismatch, file path). This is a detection report only — do not
edit any files in this repo, and do not propose specific code changes,
just name what's out of sync so a human or a future session can decide
what to do about it.
