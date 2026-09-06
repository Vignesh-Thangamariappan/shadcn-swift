import SwiftUI

/// shadcn-swift component: tokens
public extension UI.Theme {
    struct Colors {
        public var primary: Color
        public var primaryForeground: Color
        public var secondary: Color
        public var secondaryForeground: Color
        public var background: Color
        public var foreground: Color
        public var border: Color
        public var destructive: Color
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

        public static let `default` = Colors(
            primary: Color(red: 0.067, green: 0.067, blue: 0.067), // #111111
            primaryForeground: .white,
            secondary: Color(.secondarySystemBackground),
            secondaryForeground: .primary,
            background: Color(.systemBackground),
            foreground: .primary,
            border: Color(.separator),
            destructive: Color(red: 0.86, green: 0.15, blue: 0.15), // #db2626
            card: Color(.systemBackground),
            cardForeground: .primary,
            popover: Color(.systemBackground),
            popoverForeground: .primary,
            muted: Color(.secondarySystemFill),
            mutedForeground: Color(.secondaryLabel),
            accent: Color(.tertiarySystemFill),
            accentForeground: .primary,
            input: Color(.separator),
            ring: Color(red: 0.067, green: 0.067, blue: 0.067) // same as primary today, own slot
        )
    }

    struct Spacing {
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

    struct Radius {
        public var sm: CGFloat
        public var md: CGFloat
        public var lg: CGFloat

        public init(sm: CGFloat, md: CGFloat, lg: CGFloat) {
            self.sm = sm
            self.md = md
            self.lg = lg
        }

        public static let `default` = Radius(sm: 6, md: 8, lg: 12)
    }

    struct Typography {
        public var body: Font
        public var label: Font
        public var title: Font

        public init(body: Font, label: Font, title: Font) {
            self.body = body
            self.label = label
            self.title = title
        }

        public static let `default` = Typography(
            body: .system(size: 15),
            label: .system(size: 13, weight: .medium),
            title: .system(size: 20, weight: .semibold)
        )
    }
}
