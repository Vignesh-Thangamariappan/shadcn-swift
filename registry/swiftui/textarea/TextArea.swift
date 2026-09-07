import SwiftUI

/// shadcn-swift component: textarea
/// depends on: tokens
///
/// Requires iOS 16+ (`.scrollContentBackground`). Two deviations from a
/// naive port:
/// - SwiftUI's TextEditor has no built-in placeholder, so one is overlaid
///   manually and hidden once `text` is non-empty — the standard workaround.
/// - Focus is tracked LOCALLY, same reasoning as UI.Input's deviation note:
///   a child view's @FocusState can't observe focus driven from a parent.
public extension UI {
    struct TextArea: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.colorScheme) private var colorScheme
        @FocusState private var isFocused: Bool

        private let placeholder: String
        @Binding private var text: String
        private let isInvalid: Bool
        private let minHeight: CGFloat

        public init(
            _ placeholder: String,
            text: Binding<String>,
            isInvalid: Bool = false,
            minHeight: CGFloat = 64 // real shadcn's `min-h-16`
        ) {
            self.placeholder = placeholder
            self._text = text
            self.isInvalid = isInvalid
            self.minHeight = minHeight
        }

        public var body: some View {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.foreground)

                if text.isEmpty {
                    Text(placeholder)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.mutedForeground)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, theme.spacing.md) // real `px-3`
            .padding(.vertical, theme.spacing.sm)   // real `py-2`
            .frame(minHeight: minHeight)
            .background(fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            .uiShadow(theme.shadow.xs)
            .opacity(isEnabled ? 1 : 0.5)
            .animation(.easeOut(duration: 0.15), value: isFocused)
        }

        private var borderColor: Color {
            if isInvalid { return theme.colors.destructive }
            return isFocused ? theme.colors.ring : theme.colors.input
        }

        // Same reasoning as UI.Input: real shadcn is transparent in light
        // mode, `dark:bg-input/30` in dark — not one flat fill.
        private var fieldBackground: Color {
            colorScheme == .dark ? theme.colors.input.opacity(0.3) : .clear
        }
    }
}

#if DEBUG
private struct TextAreaPreview: View {
    @State private var empty = ""
    @State private var filled = "Some notes about this task."
    @State private var invalid = ""

    var body: some View {
        VStack(spacing: 12) {
            UI.TextArea("Write something...", text: $empty, minHeight: 72)
            UI.TextArea("Write something...", text: $filled, minHeight: 72)
            UI.TextArea("Required", text: $invalid, isInvalid: true, minHeight: 72)
        }
        .padding()
    }
}

#Preview("TextArea") {
    TextAreaPreview()
}
#endif
