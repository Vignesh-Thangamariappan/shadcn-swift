import SwiftUI

/// shadcn-swift component: button
/// depends on: tokens
public extension UI {
    enum ButtonVariant {
        case primary, secondary, ghost
    }

    struct Button<Label: View>: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.isEnabled) private var isEnabled

        private let variant: ButtonVariant
        private let action: () -> Void
        private let label: () -> Label

        public init(
            variant: ButtonVariant = .primary,
            action: @escaping () -> Void,
            @ViewBuilder label: @escaping () -> Label
        ) {
            self.variant = variant
            self.action = action
            self.label = label
        }

        public var body: some View {
            SwiftUI.Button(action: action) {
                label()
                    .font(theme.typography.label)
                    .padding(.horizontal, theme.spacing.md)
                    .padding(.vertical, theme.spacing.sm)
                    .frame(maxWidth: variant == .ghost ? nil : .infinity)
                    .background(background)
                    .foregroundStyle(foreground)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                            .strokeBorder(border, lineWidth: variant == .secondary ? 1 : 0)
                    )
                    .opacity(isEnabled ? 1 : 0.5)
            }
            .buttonStyle(.plain)
        }

        private var background: Color {
            switch variant {
            case .primary: theme.colors.primary
            case .secondary: theme.colors.secondary
            case .ghost: .clear
            }
        }

        private var foreground: Color {
            switch variant {
            case .primary: theme.colors.primaryForeground
            case .secondary: theme.colors.secondaryForeground
            case .ghost: theme.colors.foreground
            }
        }

        private var border: Color {
            variant == .secondary ? theme.colors.border : .clear
        }
    }
}

public extension UI.Button where Label == Text {
    init(_ titleKey: LocalizedStringKey, variant: UI.ButtonVariant = .primary, action: @escaping () -> Void) {
        self.init(variant: variant, action: action) { Text(titleKey) }
    }
}
