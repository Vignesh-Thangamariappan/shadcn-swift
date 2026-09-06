import SwiftUI

/// shadcn-swift component: checkbox
/// depends on: tokens
///
/// Deliberately NOT a ToggleStyle: `.toggleStyle(.checkbox)` only exists on
/// macOS. A checkbox on iOS is its own Binding<Bool>-driven control, built
/// the same shape as UI.Button (a plain-style Button wrapping custom
/// content) rather than reusing UI.Toggle's ToggleStyle machinery.
public extension UI {
    struct Checkbox: View {
        @Environment(\.uiTheme) private var theme

        private let label: String?
        @Binding private var isOn: Bool

        public init(_ label: String? = nil, isOn: Binding<Bool>) {
            self.label = label
            self._isOn = isOn
        }

        public var body: some View {
            SwiftUI.Button {
                isOn.toggle()
            } label: {
                HStack(spacing: theme.spacing.sm) {
                    RoundedRectangle(cornerRadius: theme.radius.sm / 2, style: .continuous)
                        .fill(isOn ? theme.colors.primary : .clear)
                        .frame(width: 20, height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radius.sm / 2, style: .continuous)
                                .strokeBorder(isOn ? .clear : theme.colors.input, lineWidth: 1)
                        )
                        .overlay {
                            if isOn {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(theme.colors.primaryForeground)
                            }
                        }

                    if let label {
                        Text(label)
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.foreground)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

#if DEBUG
private struct CheckboxPreview: View {
    @State private var checked = true
    @State private var unchecked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            UI.Checkbox("Accept terms", isOn: $checked)
            UI.Checkbox("Subscribe to updates", isOn: $unchecked)
            UI.Checkbox(isOn: $checked)
        }
        .padding()
    }
}

#Preview("Checkbox") {
    CheckboxPreview()
}
#endif
