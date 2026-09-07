import SwiftUI

/// shadcn-swift component: toggle
/// depends on: tokens
///
/// This is real shadcn's Toggle: a pressable two-state BUTTON (the
/// bold/italic toolbar idiom) — visually and behaviorally nothing like a
/// switch. A pill-and-thumb control (which is what this repo originally
/// called "toggle") is shadcn's separate `Switch` component; see
/// registry/swiftui/switch. Variants/sizes match shadcn's stock Toggle:
/// `default | outline`, `sm | default | lg`.
///
/// Corner radius is `theme.radius.md` — real shadcn's Toggle is
/// `rounded-md`. An earlier version used `sm`, one tier too tight.
///
/// Horizontal padding and the square minimum width trace to real shadcn's
/// actual per-size classes (`h-9 min-w-9 px-2` etc., fetched live from
/// `toggle.tsx`) — an earlier version's padding was roughly double these.
public extension UI {
    enum ToggleVariant {
        case `default`, outline
    }

    enum ToggleSize {
        case sm, `default`, lg
    }

    struct Toggle<Label: View>: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.isEnabled) private var isEnabled

        private let variant: ToggleVariant
        private let size: ToggleSize
        @Binding private var isOn: Bool
        private let label: () -> Label

        public init(
            isOn: Binding<Bool>,
            variant: ToggleVariant = .default,
            size: ToggleSize = .default,
            @ViewBuilder label: @escaping () -> Label
        ) {
            self._isOn = isOn
            self.variant = variant
            self.size = size
            self.label = label
        }

        public var body: some View {
            SwiftUI.Button {
                isOn.toggle()
            } label: {
                label()
                    .font(theme.typography.label)
                    .padding(.horizontal, horizontalPadding)
                    .frame(minWidth: height) // real shadcn's `min-w-9/8/10` — square minimum, for icon-only use
                    .frame(height: height)
                    .background(background)
                    .foregroundStyle(foreground)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                            .strokeBorder(variant == .outline ? theme.colors.input : .clear, lineWidth: 1)
                    )
                    .uiShadow(shadowLevel)
            }
            .buttonStyle(.plain)
            .opacity(isEnabled ? 1 : 0.5)
        }

        // Real shadcn only applies `shadow-xs` to the `outline` variant.
        private var shadowLevel: UI.Theme.Shadow.Level {
            variant == .outline ? theme.shadow.xs : UI.Theme.Shadow.Level(color: .clear, radius: 0, y: 0)
        }

        private var background: Color {
            isOn ? theme.colors.accent : .clear
        }

        private var foreground: Color {
            isOn ? theme.colors.accentForeground : theme.colors.foreground
        }

        // Real shadcn: sm=`px-1.5`(6), default=`px-2`(8), lg=`px-2.5`(10) —
        // these were roughly double real shadcn's values.
        private var horizontalPadding: CGFloat {
            switch size {
            case .sm: 6
            case .default: 8
            case .lg: 10
            }
        }

        private var height: CGFloat {
            switch size {
            case .sm: 32
            case .default: 36
            case .lg: 40
            }
        }
    }
}

public extension UI.Toggle where Label == Image {
    init(
        systemImage: String,
        isOn: Binding<Bool>,
        variant: UI.ToggleVariant = .default,
        size: UI.ToggleSize = .default
    ) {
        self.init(isOn: isOn, variant: variant, size: size) { Image(systemName: systemImage) }
    }
}

#if DEBUG
private struct ToggleButtonPreview: View {
    @State private var bold = true
    @State private var italic = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                UI.Toggle(systemImage: "bold", isOn: $bold)
                UI.Toggle(systemImage: "italic", isOn: $italic)
                UI.Toggle(systemImage: "underline", isOn: .constant(false), variant: .outline)
            }
            HStack(spacing: 8) {
                UI.Toggle(systemImage: "bold", isOn: $bold, size: .sm)
                UI.Toggle(systemImage: "bold", isOn: $bold, size: .default)
                UI.Toggle(systemImage: "bold", isOn: $bold, size: .lg)
            }
        }
        .padding()
    }
}

#Preview("Toggle") {
    ToggleButtonPreview()
}
#endif
