import SwiftUI

/// shadcn-swift component: badge
/// depends on: tokens
///
/// Variant names match real shadcn's stock `badge.tsx` `cva()` block exactly
/// (verified against a live shadcn install): `default | secondary |
/// destructive | outline`. An earlier version invented `primary` in place
/// of `default` and had no `destructive` variant — fixed.
public extension UI {
    enum BadgeVariant {
        case `default`, secondary, destructive, outline
    }

    struct Badge: View {
        @Environment(\.uiTheme) private var theme

        private let text: String
        private let variant: BadgeVariant

        public init(_ text: String, variant: BadgeVariant = .default) {
            self.text = text
            self.variant = variant
        }

        public var body: some View {
            Text(text)
                .font(theme.typography.label)
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.xs / 2)
                .background(background)
                .foregroundStyle(foreground)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(border, lineWidth: variant == .outline ? 1 : 0)
                )
        }

        private var background: Color {
            switch variant {
            case .default: theme.colors.primary
            case .secondary: theme.colors.secondary
            case .destructive: theme.colors.destructive
            case .outline: .clear
            }
        }

        private var foreground: Color {
            switch variant {
            case .default: theme.colors.primaryForeground
            case .secondary: theme.colors.secondaryForeground
            case .destructive: .white
            case .outline: theme.colors.foreground
            }
        }

        private var border: Color {
            variant == .outline ? theme.colors.border : .clear
        }
    }
}

#if DEBUG
private struct BadgePreview: View {
    var body: some View {
        HStack(spacing: 8) {
            UI.Badge("Default")
            UI.Badge("Secondary", variant: .secondary)
            UI.Badge("Destructive", variant: .destructive)
            UI.Badge("Outline", variant: .outline)
        }
        .padding()
    }
}

#Preview("Badge") {
    BadgePreview()
}
#endif
