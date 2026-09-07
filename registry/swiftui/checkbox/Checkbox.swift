import SwiftUI

/// shadcn-swift component: checkbox
/// depends on: tokens
///
/// Deliberately NOT a ToggleStyle: `.toggleStyle(.checkbox)` only exists on
/// macOS. A checkbox on iOS is its own Binding<Bool>-driven control, built
/// the same shape as UI.Button (a plain-style Button wrapping custom
/// content) rather than reusing UI.Toggle's ToggleStyle machinery.
///
/// The box's corner radius is a literal `4`, not `theme.radius.*`: real
/// shadcn's checkbox is `rounded-[4px]`, a fixed value that deliberately
/// does NOT scale with `--radius` the way every other component here does
/// (verified against the live `checkbox.tsx` source) — so hardcoding it is
/// the more faithful choice, not a shortcut. An earlier version derived it
/// from `theme.radius.sm / 2` (3px), which both got the number wrong and
/// wired it to a token real shadcn doesn't tie it to.
public extension UI {
    struct Checkbox: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.colorScheme) private var colorScheme

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
                    // Real shadcn is `size-4` (16pt); this was 20 — one size
                    // tier too big.
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isOn ? theme.colors.primary : boxBackground)
                        .frame(width: 16, height: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(isOn ? theme.colors.primary : theme.colors.input, lineWidth: 1)
                        )
                        .overlay {
                            if isOn {
                                // Real shadcn's check glyph is `size-3.5` (14pt).
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(theme.colors.primaryForeground)
                            }
                        }
                        .uiShadow(theme.shadow.xs)

                    if let label {
                        Text(label)
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.foreground)
                    }
                }
            }
            .buttonStyle(.plain)
            .opacity(isEnabled ? 1 : 0.5)
        }

        // Real shadcn's unchecked box is transparent in light mode,
        // `dark:bg-input/30` in dark — matches Input/TextArea's approach.
        private var boxBackground: Color {
            colorScheme == .dark ? theme.colors.input.opacity(0.3) : .clear
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
