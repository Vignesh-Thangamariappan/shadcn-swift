import SwiftUI

/// shadcn-swift component: badge
/// depends on: tokens
public extension UI {
    enum BadgeVariant {
        case primary, secondary, outline
    }

    struct Badge: View {
        @Environment(\.uiTheme) private var theme

        private let text: String
        private let variant: BadgeVariant

        public init(_ text: String, variant: BadgeVariant = .primary) {
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
            case .primary: theme.colors.primary
            case .secondary: theme.colors.secondary
            case .outline: .clear
            }
        }

        private var foreground: Color {
            switch variant {
            case .primary: theme.colors.primaryForeground
            case .secondary: theme.colors.secondaryForeground
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
            UI.Badge("New", variant: .primary)
            UI.Badge("Draft", variant: .secondary)
            UI.Badge("Beta", variant: .outline)
        }
        .padding()
    }
}

#Preview("Badge") {
    BadgePreview()
}
#endif
