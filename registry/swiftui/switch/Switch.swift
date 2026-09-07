import SwiftUI

/// shadcn-swift component: switch
/// depends on: tokens
///
/// This was originally shipped as our `toggle` component. A parity audit
/// against real shadcn caught that this pill-and-sliding-thumb control is
/// what shadcn calls `Switch` — shadcn's actual `Toggle` is a completely
/// different, unrelated component (a pressable two-state button, the
/// bold/italic toolbar idiom). Renamed to match; see registry/swiftui/toggle
/// for the real Toggle.
///
/// Implemented as a custom ToggleStyle rather than `.tint()` or the deprecated
/// `SwitchToggleStyle(tint:)` — both are OS-version-dependent about which
/// colors they actually honor. A custom style reads colors straight from the
/// theme, same guarantee every other component in this registry makes.
public extension UI {
    struct SwitchToggleStyle: ToggleStyle {
        let theme: UI.Theme

        // Real shadcn's default-size Switch is `h-[1.15rem] w-8` (18.4×32pt)
        // with a `size-4` (16pt) thumb — this was 24×44 with a hardcoded
        // circle inset, noticeably larger than the real control on every
        // dimension. Off-state track is `bg-input`, not `secondary`
        // (`secondary` is a button-variant background, an unrelated slot).
        public func makeBody(configuration: Configuration) -> some View {
            Button {
                configuration.isOn.toggle()
            } label: {
                Capsule()
                    .fill(configuration.isOn ? theme.colors.primary : theme.colors.input)
                    .frame(width: 32, height: 18)
                    .overlay(
                        Circle()
                            .fill(theme.colors.background)
                            .frame(width: 16, height: 16)
                            .offset(x: configuration.isOn ? 7 : -7)
                    )
                    .animation(.easeOut(duration: 0.15), value: configuration.isOn)
            }
            .buttonStyle(.plain)
        }
    }

    struct Switch: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.isEnabled) private var isEnabled

        private let label: String
        @Binding private var isOn: Bool

        public init(_ label: String, isOn: Binding<Bool>) {
            self.label = label
            self._isOn = isOn
        }

        public var body: some View {
            SwiftUI.Toggle(label, isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(theme: theme))
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.foreground)
                .opacity(isEnabled ? 1 : 0.5)
        }
    }
}

#if DEBUG
private struct SwitchPreview: View {
    @State private var on = true
    @State private var off = false

    var body: some View {
        VStack(spacing: 12) {
            UI.Switch("On", isOn: $on)
            UI.Switch("Off", isOn: $off)
        }
        .padding()
    }
}

#Preview("Switch") {
    SwitchPreview()
}
#endif
