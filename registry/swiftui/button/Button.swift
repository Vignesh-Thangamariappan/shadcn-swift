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
///
/// `shape: .full` reproduces real shadcn's `rounded-full` override
/// (`UI.Theme.CornerStyle`, defined in `tokens/Tokens.swift`) — a real
/// parameter, not an external `.clipShape(Capsule())` layered on afterward,
/// since SwiftUI's clip shapes intersect rather than replace one another.
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
        private let shape: UI.Theme.CornerStyle?
        // Not part of any public initializer — `UI.ButtonGroup` is the only
        // intended setter, via `buttonGroupPosition(_:orientation:)` below.
        // No direct caller should construct a "grouped standalone" Button.
        private var groupPosition: UI.Theme.SegmentPosition = .standalone
        private var groupOrientation: UI.Theme.SegmentOrientation = .horizontal

        public init(
            variant: ButtonVariant = .default,
            size: ButtonSize = .default,
            shape: UI.Theme.CornerStyle? = nil,
            action: @escaping () -> Void,
            @ViewBuilder label: @escaping () -> Label
        ) {
            self.variant = variant
            self.size = size
            self.shape = shape
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
            shape: UI.Theme.CornerStyle?,
            hasIcon: Bool,
            action: @escaping () -> Void,
            @ViewBuilder label: @escaping () -> Label
        ) {
            self.variant = variant
            self.size = size
            self.shape = shape
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
                    .clipShape(cornerShape)
                    .overlay(alignment: .center) { borderOverlay }
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

        // Real shadcn's `rounded-full` is a `className` override that
        // replaces the base `rounded-md` class outright — Tailwind's class
        // merge is a replace, not a stack. SwiftUI's `.clipShape` stacks
        // (intersects) instead, so a `Capsule()` clipped on top of an
        // already-`RoundedRectangle`-clipped view has no visible effect;
        // `shape` has to be a real parameter this button applies at its own
        // clip/overlay sites. `nil` keeps this button's own default tier.
        private var cornerRadius: CGFloat {
            (shape ?? .radius(theme.radius.md)).cornerRadius
        }

        // Real shadcn's `ButtonGroup` rounds only the OUTER corners of the
        // first/last member (`rounded-l-none`/`rounded-r-none`, mirrored for
        // `vertical` with top/bottom) — verified live against
        // `button-group.tsx`. `.standalone` (the default) rounds all four
        // corners as before; `UI.ButtonGroup` is the only thing that ever
        // sets `groupPosition` away from that.
        private var cornerShape: UnevenRoundedRectangle {
            let r = cornerRadius
            switch (groupOrientation, groupPosition) {
            case (_, .standalone):
                return UnevenRoundedRectangle(topLeadingRadius: r, bottomLeadingRadius: r, bottomTrailingRadius: r, topTrailingRadius: r, style: .continuous)
            case (_, .middle):
                return UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 0, style: .continuous)
            case (.horizontal, .leading):
                return UnevenRoundedRectangle(topLeadingRadius: r, bottomLeadingRadius: r, bottomTrailingRadius: 0, topTrailingRadius: 0, style: .continuous)
            case (.horizontal, .trailing):
                return UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: r, topTrailingRadius: r, style: .continuous)
            case (.vertical, .leading):
                return UnevenRoundedRectangle(topLeadingRadius: r, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: r, style: .continuous)
            case (.vertical, .trailing):
                return UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: r, bottomTrailingRadius: r, topTrailingRadius: 0, style: .continuous)
            }
        }

        // Real shadcn's ButtonGroup also collapses the shared border between
        // adjacent members to one line (`border-l-0`/`border-t-0` on every
        // member but the first) — same technique as `UI.Toggle`'s own
        // grouped border, generalized to both orientations in
        // `UI.Theme.PartialBorderShape` (`tokens/Tokens.swift`).
        @ViewBuilder
        private var borderOverlay: some View {
            let width: CGFloat = variant == .outline ? 1 : 0
            switch (groupOrientation, groupPosition) {
            case (_, .standalone), (_, .leading):
                cornerShape.strokeBorder(border, lineWidth: width)
            case (let orientation, .middle):
                UI.Theme.PartialBorderShape(orientation: orientation, farCornerRadius: 0)
                    .stroke(border, lineWidth: width)
            case (let orientation, .trailing):
                UI.Theme.PartialBorderShape(orientation: orientation, farCornerRadius: cornerRadius)
                    .stroke(border, lineWidth: width)
            }
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

        /// `UI.ButtonGroup`-only. Not public: no direct caller should
        /// construct a "grouped standalone" Button — see the stored
        /// properties' own doc comment above for why this isn't threaded
        /// through the public initializers instead.
        func buttonGroupPosition(_ position: UI.Theme.SegmentPosition, orientation: UI.Theme.SegmentOrientation) -> Self {
            var copy = self
            copy.groupPosition = position
            copy.groupOrientation = orientation
            return copy
        }
    }
}

public extension UI.Button where Label == Text {
    init(
        _ titleKey: LocalizedStringKey,
        variant: UI.ButtonVariant = .default,
        size: UI.ButtonSize = .default,
        shape: UI.Theme.CornerStyle? = nil,
        action: @escaping () -> Void
    ) {
        self.init(variant: variant, size: size, shape: shape, action: action) { Text(titleKey) }
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
            // `Image` has no dedicated `font(_:) -> Image` overload of its
            // own (verified: forcing that return type is a real compile
            // error, not a resolvable ambiguity) — `View.font(_:) -> some
            // View` is the only candidate, and it's the correct, standard
            // way to size an SF Symbol image; it isn't a workaround.
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
        shape: UI.Theme.CornerStyle? = nil,
        action: @escaping () -> Void
    ) {
        self.init(variant: variant, size: size, shape: shape, hasIcon: true, action: action) {
            UI.ButtonIconLabel(icon: icon, title: Text(titleKey), gap: iconGap(for: size), trailing: false)
        }
    }

    /// A button with a trailing icon after its title.
    init(
        _ titleKey: LocalizedStringKey,
        trailingIcon icon: Image,
        variant: UI.ButtonVariant = .default,
        size: UI.ButtonSize = .default,
        shape: UI.Theme.CornerStyle? = nil,
        action: @escaping () -> Void
    ) {
        self.init(variant: variant, size: size, shape: shape, hasIcon: true, action: action) {
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
        shape: UI.Theme.CornerStyle? = nil,
        action: @escaping () -> Void
    ) {
        self.init(variant: variant, size: size, shape: shape, hasIcon: true, action: action) {
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

            HStack(spacing: 12) {
                UI.Button("Rounded full", shape: .full, action: {})
                UI.Button(icon: Image(systemName: "plus"), shape: .full, action: {})
            }
        }
        .padding()
    }
}

#Preview("Button") {
    ButtonPreview()
}
#endif
