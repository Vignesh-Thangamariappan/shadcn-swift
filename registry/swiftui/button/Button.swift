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
///
/// Icon convenience inits (`icon:`/`trailingIcon:`) match real shadcn's
/// icon-bearing button exactly, verified against the live `button.tsx`
/// source: icon is sized `size-4` (16pt) for every size this port has
/// (`sm`/`default`/`lg` — real shadcn's smaller `size-3`/12pt icon only
/// applies to an `xs` button size this port doesn't have), the icon/label
/// gap is `gap-1.5` (6pt) for `.sm` and the base `gap-2` (8pt) for every
/// other size (`.sm` is the one size that overrides the base gap), and
/// horizontal padding tightens when an icon is present (`has-[>svg]:px-*`)
/// — 12pt/10pt/16pt for default/sm/lg instead of 16pt/12pt/24pt.
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
        private let hasIcon: Bool

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
            self.hasIcon = false
        }

        /// Only the icon-convenience inits below use this — `hasIcon` gates
        /// the `has-[>svg]:px-*` tightened padding real shadcn applies
        /// whenever a button carries an icon child.
        fileprivate init(
            variant: ButtonVariant,
            size: ButtonSize,
            hasIcon: Bool,
            action: @escaping () -> Void,
            @ViewBuilder label: @escaping () -> Label
        ) {
            self.variant = variant
            self.size = size
            self.action = action
            self.label = label
            self.hasIcon = hasIcon
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
            case .sm: hasIcon ? 10 : 12
            case .default: hasIcon ? 12 : 16
            case .lg: hasIcon ? 16 : 24
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

/// Icon/label gap — real shadcn's `.sm` size is the one that overrides the
/// base `gap-2` (8pt) down to `gap-1.5` (6pt).
private func iconGap(for size: UI.ButtonSize) -> CGFloat {
    size == .sm ? 6 : 8
}

/// Real shadcn sizes any icon child to `size-4` (16pt) unless it already
/// carries its own size class — verified against the live `button.tsx`
/// source (`[&_svg:not([class*='size-'])]:size-4`).
public extension UI {
    struct ButtonIconLabel: View {
        let icon: Image
        let title: Text?
        let gap: CGFloat
        let trailing: Bool

        public var body: some View {
            HStack(spacing: gap) {
                if trailing { title }
                icon.font(.system(size: 16))
                if !trailing { title }
            }
        }
    }
}

public extension UI.Button where Label == UI.ButtonIconLabel {
    /// A button with a leading icon before its title.
    init(
        _ titleKey: LocalizedStringKey,
        icon: Image,
        variant: UI.ButtonVariant = .default,
        size: UI.ButtonSize = .default,
        action: @escaping () -> Void
    ) {
        self.init(variant: variant, size: size, hasIcon: true, action: action) {
            UI.ButtonIconLabel(icon: icon, title: Text(titleKey), gap: iconGap(for: size), trailing: false)
        }
    }

    /// A button with a trailing icon after its title.
    init(
        _ titleKey: LocalizedStringKey,
        trailingIcon icon: Image,
        variant: UI.ButtonVariant = .default,
        size: UI.ButtonSize = .default,
        action: @escaping () -> Void
    ) {
        self.init(variant: variant, size: size, hasIcon: true, action: action) {
            UI.ButtonIconLabel(icon: icon, title: Text(titleKey), gap: iconGap(for: size), trailing: true)
        }
    }
}

public extension UI.Button where Label == UI.ButtonIconLabel {
    /// An icon-only button (no title) — sizes its icon to `size-4` (16pt)
    /// the same way the title-bearing icon inits above do, so a caller
    /// doesn't have to hand-size a bare `Image` themselves.
    init(
        icon: Image,
        variant: UI.ButtonVariant = .default,
        size: UI.ButtonSize = .icon,
        action: @escaping () -> Void
    ) {
        self.init(variant: variant, size: size, action: action) {
            UI.ButtonIconLabel(icon: icon, title: nil, gap: 0, trailing: false)
        }
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
                UI.Button(icon: Image(systemName: "plus"), action: {})
            }

            HStack(spacing: 12) {
                UI.Button("Download", icon: Image(systemName: "arrow.down.circle"), action: {})
                UI.Button("Next", trailingIcon: Image(systemName: "arrow.right"), variant: .outline, action: {})
                UI.Button("Small", icon: Image(systemName: "star"), size: .sm, action: {})
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
