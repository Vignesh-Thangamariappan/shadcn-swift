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

        public init(
            primary: Color,
            primaryForeground: Color,
            secondary: Color,
            secondaryForeground: Color,
            background: Color,
            foreground: Color,
            border: Color
        ) {
            self.primary = primary
            self.primaryForeground = primaryForeground
            self.secondary = secondary
            self.secondaryForeground = secondaryForeground
            self.background = background
            self.foreground = foreground
            self.border = border
        }

        public static let `default` = Colors(
            primary: Color(red: 0.067, green: 0.067, blue: 0.067), // #111111
            primaryForeground: .white,
            secondary: Color(.secondarySystemBackground),
            secondaryForeground: .primary,
            background: Color(.systemBackground),
            foreground: .primary,
            border: Color(.separator)
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
