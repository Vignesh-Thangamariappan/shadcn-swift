import SwiftUI

/// shadcn-swift component: toggle
/// depends on: tokens
///
/// Implemented as a custom ToggleStyle rather than `.tint()` or the deprecated
/// `SwitchToggleStyle(tint:)` — both are OS-version-dependent about which
/// colors they actually honor. A custom style reads colors straight from the
/// theme, same guarantee every other component in this registry makes.
public extension UI {
    struct SwitchToggleStyle: ToggleStyle {
        let theme: UI.Theme

        public func makeBody(configuration: Configuration) -> some View {
            Button {
                configuration.isOn.toggle()
            } label: {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(configuration.isOn ? theme.colors.primary : theme.colors.secondary)
                    .frame(width: 44, height: 24)
                    .overlay(
                        Circle()
                            .fill(theme.colors.background)
                            .padding(2)
                            .offset(x: configuration.isOn ? 10 : -10)
                    )
                    .animation(.easeOut(duration: 0.15), value: configuration.isOn)
            }
            .buttonStyle(.plain)
        }
    }

    struct Toggle: View {
        @Environment(\.uiTheme) private var theme

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
        }
    }
}
