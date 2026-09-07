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
        @Environment(\.colorScheme) private var colorScheme

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
                    // Real shadcn's `outline` variant alone carries `shadow-xs`
                    // (verified against the live `button.tsx` source) — every
                    // other variant is shadowless.
                    .uiShadow(variant == .outline ? theme.shadow.xs : UI.Theme.Shadow.Level(color: .clear, radius: 0, y: 0))
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

        // real shadcn's `outline` (`bg-background`/`dark:bg-input/30`) and
        // `destructive` (`dark:bg-destructive/60`) variants both carry a
        // light/dark-specific background that a single flat token can't
        // express — verified against the live `button.tsx` source, same
        // fetch this file's other doc comments already cite.
        private var background: Color {
            switch variant {
            case .default: theme.colors.primary
            case .destructive: colorScheme == .dark ? theme.colors.destructive.opacity(0.6) : theme.colors.destructive
            case .outline: colorScheme == .dark ? theme.colors.input.opacity(0.3) : theme.colors.background
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
