import SwiftUI

/// shadcn-swift component: button
/// depends on: tokens
///
/// Variant/size API matches real shadcn's stock `button.tsx` `cva()` block
/// exactly (verified against a live shadcn install, not memory):
/// variants `default | destructive | outline | secondary | ghost | link`,
/// sizes `sm | default | lg | icon`. An earlier version of this component
/// invented a `primary` variant name and had no size prop at all — fixed.
///
/// Also fixed here: buttons no longer stretch to `.infinity` width by
/// default. Real shadcn's Button is `inline-flex` — sized to its content,
/// not full-width — and the earlier version's `frame(maxWidth: .infinity)`
/// was a silent deviation from that.
public extension UI {
    enum ButtonVariant {
        case `default`, destructive, outline, secondary, ghost, link
    }

    enum ButtonSize {
        case sm, `default`, lg, icon
    }

    struct Button<Label: View>: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.isEnabled) private var isEnabled

        private let variant: ButtonVariant
        private let size: ButtonSize
        private let action: () -> Void
        private let label: () -> Label

        public init(
            variant: ButtonVariant = .default,
            size: ButtonSize = .default,
            action: @escaping () -> Void,
            @ViewBuilder label: @escaping () -> Label
        ) {
            self.variant = variant
            self.size = size
            self.action = action
            self.label = label
        }

        public var body: some View {
            SwiftUI.Button(action: action) {
                label()
                    .font(font)
                    .lineLimit(1)
                    .padding(.horizontal, horizontalPadding)
                    .frame(height: height)
                    .frame(width: size == .icon ? height : nil)
                    .background(background)
                    .foregroundStyle(foreground)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                            .strokeBorder(border, lineWidth: variant == .outline ? 1 : 0)
                    )
                    .underline(variant == .link)
            }
            .buttonStyle(.plain)
            .opacity(isEnabled ? 1 : 0.5)
        }

        private var font: Font {
            size == .lg ? theme.typography.body : theme.typography.label
        }

        private var horizontalPadding: CGFloat {
            switch size {
            case .sm: 12
            case .default: 16
            case .lg: 24
            case .icon: 0
            }
        }

        private var height: CGFloat {
            switch size {
            case .sm: 32
            case .default: 36
            case .lg: 40
            case .icon: 36
            }
        }

        private var background: Color {
            switch variant {
            case .default: theme.colors.primary
            case .destructive: theme.colors.destructive
            case .outline: .clear
            case .secondary: theme.colors.secondary
            case .ghost: .clear
            case .link: .clear
            }
        }

        private var foreground: Color {
            switch variant {
            case .default: theme.colors.primaryForeground
            case .destructive: .white
            case .outline: theme.colors.foreground
            case .secondary: theme.colors.secondaryForeground
            case .ghost: theme.colors.foreground
            case .link: theme.colors.primary
            }
        }

        private var border: Color {
            variant == .outline ? theme.colors.input : .clear
        }
    }
}

public extension UI.Button where Label == Text {
    init(
        _ titleKey: LocalizedStringKey,
        variant: UI.ButtonVariant = .default,
        size: UI.ButtonSize = .default,
        action: @escaping () -> Void
    ) {
        self.init(variant: variant, size: size, action: action) { Text(titleKey) }
    }
}

#if DEBUG
private struct ButtonPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            UI.Button("Default") {}
            UI.Button("Destructive", variant: .destructive) {}
            UI.Button("Outline", variant: .outline) {}
            UI.Button("Secondary", variant: .secondary) {}
            UI.Button("Ghost", variant: .ghost) {}
            UI.Button("Link", variant: .link) {}

            HStack(spacing: 12) {
                UI.Button("Small", size: .sm) {}
                UI.Button("Default", size: .default) {}
                UI.Button("Large", size: .lg) {}
                UI.Button(size: .icon, action: {}) {
                    Image(systemName: "plus")
                }
            }

            UI.Button("Disabled") {}
                .disabled(true)
        }
        .padding()
    }
}

#Preview("Button") {
    ButtonPreview()
}
#endif
