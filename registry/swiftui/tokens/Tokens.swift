import SwiftUI
import UIKit

/// shadcn-swift component: tokens
///
/// `Color.dynamic(light:dark:)` mirrors real shadcn's CSS: its `:root` and
/// `.dark` blocks give every token two literal values, not one value that's
/// computed to look right in both. `UIColor { traits in ... }` is SwiftUI's
/// equivalent of that — it resolves at render time from `userInterfaceStyle`,
/// so every existing `theme.colors.primary`-style call site across the whole
/// registry gets correct dark-mode colors for free, with zero changes to
/// those files. Kept private: a theme author only ever sees the finished
/// `Color`, the same way a CSS custom property looks like one value at any
/// given moment.
private extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

public extension UI.Theme {
    struct Colors: Sendable {
        public var primary: Color
        public var primaryForeground: Color
        public var secondary: Color
        public var secondaryForeground: Color
        public var background: Color
        public var foreground: Color
        public var border: Color
        public var destructive: Color
        /// Text/icon color for content placed directly on `destructive`
        /// (real shadcn's `--destructive-foreground`). Several components
        /// (Button, Badge) instead hardcode plain white for this slot in
        /// their own Tailwind classes rather than referencing the CSS var —
        /// this token exists for the ones that do reference it, and as the
        /// correct value to fall back to.
        public var destructiveForeground: Color
        /// Card/Alert surface — a distinct slot from `background` even though
        /// they default to the same value, per real shadcn's own stock theme.
        /// The point is call sites say which SURFACE they mean, so the two can
        /// diverge later (e.g. a card on a tinted page) without a find-replace.
        public var card: Color
        public var cardForeground: Color
        /// Popover/Select/Combobox/Tooltip surfaces.
        public var popover: Color
        public var popoverForeground: Color
        /// Secondary text, disabled states, skeleton fill — distinct from
        /// `secondary` (a button-variant background), the exact conflation
        /// this token set used to have.
        public var muted: Color
        public var mutedForeground: Color
        /// Hover/selected/pressed row backgrounds (e.g. a pressed UI.Toggle).
        public var accent: Color
        public var accentForeground: Color
        /// Form-control border — distinct from generic `border`.
        public var input: Color
        /// Focus ring — distinct from `primary`; overriding one shouldn't
        /// force re-theming the other.
        public var ring: Color

        public init(
            primary: Color,
            primaryForeground: Color,
            secondary: Color,
            secondaryForeground: Color,
            background: Color,
            foreground: Color,
            border: Color,
            destructive: Color,
            destructiveForeground: Color,
            card: Color,
            cardForeground: Color,
            popover: Color,
            popoverForeground: Color,
            muted: Color,
            mutedForeground: Color,
            accent: Color,
            accentForeground: Color,
            input: Color,
            ring: Color
        ) {
            self.primary = primary
            self.primaryForeground = primaryForeground
            self.secondary = secondary
            self.secondaryForeground = secondaryForeground
            self.background = background
            self.foreground = foreground
            self.border = border
            self.destructive = destructive
            self.destructiveForeground = destructiveForeground
            self.card = card
            self.cardForeground = cardForeground
            self.popover = popover
            self.popoverForeground = popoverForeground
            self.muted = muted
            self.mutedForeground = mutedForeground
            self.accent = accent
            self.accentForeground = accentForeground
            self.input = input
            self.ring = ring
        }

        /// Every value below is real shadcn's actual default theme — the
        /// `:root` (light) and `.dark` OKLCH blocks in `apps/v4/app/globals.css`
        /// in the real shadcn/ui repo, fetched live and converted to sRGB by
        /// hand (OKLCH → OKLab → linear sRGB → gamma-encoded sRGB, Björn
        /// Ottosson's reference conversion: https://bottosson.github.io/posts/oklab/).
        /// This replaces the previous approach of riding on iOS system
        /// dynamic colors (`Color(.systemBackground)` etc.) — that was
        /// idiomatic-iOS but not a real match to shadcn's own palette, and
        /// left `primary`/`destructive`/`ring` hardcoded to light-mode-only
        /// hex that didn't adapt in dark mode at all. Every slot here now
        /// has an explicit, correct value in both modes.
        public static let `default` = Colors(
            // oklch(0% 0 0) / oklch(0.922 0 0)
            primary: .dynamic(light: Color(red: 0, green: 0, blue: 0), dark: Color(red: 0.8982, green: 0.8982, blue: 0.8982)),
            // oklch(0.985 0 0) / oklch(0.205 0 0)
            primaryForeground: .dynamic(light: Color(red: 0.9803, green: 0.9803, blue: 0.9803), dark: Color(red: 0.0905, green: 0.0905, blue: 0.0905)),
            // oklch(0.97 0 0) / oklch(0.269 0 0)
            secondary: .dynamic(light: Color(red: 0.9606, green: 0.9606, blue: 0.9606), dark: Color(red: 0.1494, green: 0.1494, blue: 0.1494)),
            // oklch(0.205 0 0) / oklch(0.985 0 0)
            secondaryForeground: .dynamic(light: Color(red: 0.0905, green: 0.0905, blue: 0.0905), dark: Color(red: 0.9803, green: 0.9803, blue: 0.9803)),
            // oklch(1 0 0) / oklch(0.145 0 0)
            background: .dynamic(light: Color(red: 1, green: 1, blue: 1), dark: Color(red: 0.0394, green: 0.0394, blue: 0.0394)),
            // oklch(0% 0 0) / oklch(0.985 0 0)
            foreground: .dynamic(light: Color(red: 0, green: 0, blue: 0), dark: Color(red: 0.9803, green: 0.9803, blue: 0.9803)),
            // oklch(0.922 0 0) / oklch(1 0 0 / 10%) — dark border is translucent white over the surface, not an opaque gray
            border: .dynamic(light: Color(red: 0.8982, green: 0.8982, blue: 0.8982), dark: Color.white.opacity(0.10)),
            // oklch(0.577 0.245 27.325) / oklch(0.704 0.191 22.216)
            destructive: .dynamic(light: Color(red: 0.9065, green: 0, blue: 0.0422), dark: Color(red: 1.0, green: 0.3912, blue: 0.4039)),
            // oklch(0.97 0.01 17) / oklch(0.58 0.22 27)
            destructiveForeground: .dynamic(light: Color(red: 0.9876, green: 0.9511, blue: 0.9513), dark: Color(red: 0.8742, green: 0.1327, blue: 0.1467)),
            // oklch(1 0 0) / oklch(0.205 0 0)
            card: .dynamic(light: Color(red: 1, green: 1, blue: 1), dark: Color(red: 0.0905, green: 0.0905, blue: 0.0905)),
            // oklch(0% 0 0) / oklch(0.985 0 0)
            cardForeground: .dynamic(light: Color(red: 0, green: 0, blue: 0), dark: Color(red: 0.9803, green: 0.9803, blue: 0.9803)),
            // oklch(1 0 0) / oklch(0.205 0 0)
            popover: .dynamic(light: Color(red: 1, green: 1, blue: 1), dark: Color(red: 0.0905, green: 0.0905, blue: 0.0905)),
            // oklch(0% 0 0) / oklch(0.985 0 0)
            popoverForeground: .dynamic(light: Color(red: 0, green: 0, blue: 0), dark: Color(red: 0.9803, green: 0.9803, blue: 0.9803)),
            // oklch(0.97 0 0) / oklch(0.269 0 0)
            muted: .dynamic(light: Color(red: 0.9606, green: 0.9606, blue: 0.9606), dark: Color(red: 0.1494, green: 0.1494, blue: 0.1494)),
            // oklch(0.556 0 0) / oklch(0.708 0 0)
            mutedForeground: .dynamic(light: Color(red: 0.4515, green: 0.4515, blue: 0.4515), dark: Color(red: 0.6302, green: 0.6302, blue: 0.6302)),
            // oklch(0.97 0 0) / oklch(0.371 0 0)
            accent: .dynamic(light: Color(red: 0.9606, green: 0.9606, blue: 0.9606), dark: Color(red: 0.2505, green: 0.2505, blue: 0.2505)),
            // oklch(0.205 0 0) / oklch(0.985 0 0)
            accentForeground: .dynamic(light: Color(red: 0.0905, green: 0.0905, blue: 0.0905), dark: Color(red: 0.9803, green: 0.9803, blue: 0.9803)),
            // oklch(0.922 0 0) / oklch(1 0 0 / 15%) — same translucent-white pattern as `border`
            input: .dynamic(light: Color(red: 0.8982, green: 0.8982, blue: 0.8982), dark: Color.white.opacity(0.15)),
            // oklch(0.708 0 0) / oklch(0.556 0 0)
            ring: .dynamic(light: Color(red: 0.6302, green: 0.6302, blue: 0.6302), dark: Color(red: 0.4515, green: 0.4515, blue: 0.4515))
        )
    }

    struct Spacing: Sendable {
        public var xs: CGFloat
        public var sm: CGFloat
        public var md: CGFloat
        public var lg: CGFloat
        public var xl: CGFloat

        public init(xs: CGFloat, sm: CGFloat, md: CGFloat, lg: CGFloat, xl: CGFloat) {
            self.xs = xs
            self.sm = sm
            self.md = md
            self.lg = lg
            self.xl = xl
        }

        public static let `default` = Spacing(xs: 4, sm: 8, md: 12, lg: 16, xl: 24)
    }

    struct Radius: Sendable {
        public var sm: CGFloat
        public var md: CGFloat
        public var lg: CGFloat
        public var xl: CGFloat

        public init(sm: CGFloat, md: CGFloat, lg: CGFloat, xl: CGFloat) {
            self.sm = sm
            self.md = md
            self.lg = lg
            self.xl = xl
        }

        /// Matches real shadcn's computed `--radius-*` scale exactly
        /// (`--radius: 0.625rem` = 10px; `sm`/`md`/`lg`/`xl` are that base
        /// times 0.6/0.8/1/1.4 — verified against `apps/v4/app/globals.css`
        /// in the real shadcn/ui repo, not memory). `lg` was previously 12,
        /// a guess that didn't match either real `lg` (10) or `xl` (14).
        public static let `default` = Radius(sm: 6, md: 8, lg: 10, xl: 14)
    }

    /// A component's own corner treatment: one of `Radius`'s tiers, or a
    /// full pill (real shadcn's `rounded-full` override, e.g.
    /// `<Button className="rounded-full">`). That override doesn't
    /// translate here: SwiftUI clip shapes intersect rather than replace,
    /// so stacking a second `.clipShape(Capsule())` on a view already
    /// clipped to a smaller `RoundedRectangle` has no visible effect — the
    /// tighter shape already cut the corners. `.full` has to be a real
    /// parameter each affected component's own initializer accepts and
    /// applies at its own clip/overlay call sites instead. It renders as a
    /// `RoundedRectangle` whose radius exceeds half the view's shortest
    /// side, which SwiftUI clamps to the same shape a `Capsule()` would
    /// draw — no second shape type or `AnyShape` needed.
    enum CornerStyle: Sendable {
        case radius(CGFloat)
        case full

        var cornerRadius: CGFloat {
            switch self {
            case .radius(let value): return value
            case .full: return .greatestFiniteMagnitude
            }
        }
    }

    /// Sizes/weights trace to real shadcn's actual Tailwind classes, fetched
    /// live from `label.tsx` (`text-sm font-medium`), `badge.tsx` (`text-xs
    /// font-medium`), `card.tsx` (`CardTitle`: no size class = the browser
    /// default 16px, `font-semibold`), `alert.tsx`/`empty.tsx` (description
    /// text: `text-sm`, regular weight), and `dialog.tsx` (`DialogTitle`:
    /// `text-lg font-semibold`) — not memory. Tailwind's default type scale
    /// (unmodified in this app, no `--text-*` override found in its CSS):
    /// `text-xs`=12px, `text-sm`=14px, `text-base`=16px, `text-lg`=18px.
    /// `caption` is new (nothing here needed 12px before). `body`/`label`
    /// were both off by a point (15→14, 13→14) and `title` was oversized
    /// (20→18, and real shadcn has no larger heading tier than this in any
    /// component checked — `text-lg` is the ceiling, not a guess this repo
    /// made up). Some components need `title` at `.medium` instead of the
    /// default `.semibold` (e.g. `EmptyTitle` is `text-lg font-medium`) —
    /// that's a per-call-site `.fontWeight(.medium)` override, not a
    /// separate tier, matching how real shadcn also just repeats the same
    /// `text-lg` class at a different weight rather than sharing a "heading"
    /// utility.
    struct Typography: Sendable {
        public var caption: Font
        public var body: Font
        public var label: Font
        public var title: Font

        public init(caption: Font, body: Font, label: Font, title: Font) {
            self.caption = caption
            self.body = body
            self.label = label
            self.title = title
        }

        public static let `default` = Typography(
            caption: .system(size: 12, weight: .medium),
            body: .system(size: 14),
            label: .system(size: 14, weight: .medium),
            title: .system(size: 18, weight: .semibold)
        )
    }

    /// Real shadcn's `shadow-sm`/`md`/`lg` are each TWO stacked CSS
    /// box-shadows, not one — verified against Tailwind v4's own default
    /// theme (`packages/tailwindcss/theme.css` in the real `tailwindlabs/
    /// tailwindcss` repo; shadcn's own CSS doesn't override these, checked
    /// too): `shadow-xs`=`0 1px 2px 0 rgb(0 0 0/.05)`; `shadow-sm`=`0 1px 3px
    /// 0 rgb(0 0 0/.1), 0 1px 2px -1px rgb(0 0 0/.1)`; `shadow-md`=`0 4px 6px
    /// -1px rgb(0 0 0/.1), 0 2px 4px -2px rgb(0 0 0/.1)`; `shadow-lg`=`0 10px
    /// 15px -3px rgb(0 0 0/.1), 0 4px 6px -4px rgb(0 0 0/.1)`. `Level` now
    /// holds an array of layers so multi-layer tiers render as genuinely
    /// stacked `.shadow()` calls via `.uiShadow(_:)`, not a lossy single-
    /// layer average — a real fidelity upgrade over this token's first cut.
    /// One honest, unavoidable gap: CSS's negative `spread-radius` (the
    /// third length in each layer above) has no SwiftUI `.shadow()`
    /// equivalent, so it's dropped from the conversion — the visual effect
    /// of a small negative spread is subtle at these sizes, but this is a
    /// real, deliberate approximation, not a hidden one. All four tiers
    /// exist now because component sweeps across this whole registry
    /// evidenced a real, specific need for each: `xs` (input/button-outline/
    /// select-trigger), `sm` (card/tabs-active-pill), `md` (popover — real
    /// shadcn's `select-content`/`dropdown-menu-content` also use `md`, but
    /// those render as native OS menu/picker chrome here, not a shadow this
    /// token controls), `lg` (dialog).
    struct Shadow: Sendable {
        public struct Layer: Sendable {
            public var color: Color
            public var radius: CGFloat
            public var x: CGFloat
            public var y: CGFloat

            public init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
                self.color = color
                self.radius = radius
                self.x = x
                self.y = y
            }
        }

        public struct Level: Sendable {
            public var layers: [Layer]

            /// Single-layer convenience — also how call sites express "no
            /// shadow" (`Level(color: .clear, radius: 0, y: 0)`).
            public init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
                self.layers = [Layer(color: color, radius: radius, x: x, y: y)]
            }

            /// Real multi-layer construction, for tiers with more than one
            /// stacked CSS box-shadow.
            public init(layers: [Layer]) {
                self.layers = layers
            }
        }

        public var xs: Level
        public var sm: Level
        public var md: Level
        public var lg: Level

        public init(xs: Level, sm: Level, md: Level, lg: Level) {
            self.xs = xs
            self.sm = sm
            self.md = md
            self.lg = lg
        }

        public static let `default` = Shadow(
            // 0 1px 2px 0 rgb(0 0 0/.05)
            xs: Level(color: .black.opacity(0.05), radius: 2, y: 1),
            // 0 1px 3px 0 rgb(0 0 0/.1), 0 1px 2px -1px rgb(0 0 0/.1)
            sm: Level(layers: [
                Layer(color: .black.opacity(0.10), radius: 3, y: 1),
                Layer(color: .black.opacity(0.10), radius: 2, y: 1)
            ]),
            // 0 4px 6px -1px rgb(0 0 0/.1), 0 2px 4px -2px rgb(0 0 0/.1)
            md: Level(layers: [
                Layer(color: .black.opacity(0.10), radius: 6, y: 4),
                Layer(color: .black.opacity(0.10), radius: 4, y: 2)
            ]),
            // 0 10px 15px -3px rgb(0 0 0/.1), 0 4px 6px -4px rgb(0 0 0/.1)
            lg: Level(layers: [
                Layer(color: .black.opacity(0.10), radius: 15, y: 10),
                Layer(color: .black.opacity(0.10), radius: 6, y: 4)
            ])
        )
    }
}

public extension View {
    /// Applies a `UI.Theme.Shadow.Level` token, e.g. `.uiShadow(theme.shadow.sm)`.
    /// Stacks every layer as its own `.shadow()` call, matching how CSS
    /// renders multiple `box-shadow` layers. Real shadcn's shadows are
    /// colorless (pure black at low opacity) in both light and dark mode,
    /// so this doesn't need a dark-mode variant the way `Colors` does.
    func uiShadow(_ level: UI.Theme.Shadow.Level) -> some View {
        level.layers.reduce(AnyView(self)) { view, layer in
            AnyView(view.shadow(color: layer.color, radius: layer.radius, x: layer.x, y: layer.y))
        }
    }
}
