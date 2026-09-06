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
        @FocusState private var isFocused: Bool

        private let placeholder: String
        @Binding private var text: String
        private let isInvalid: Bool
        private let minHeight: CGFloat

        public init(
            _ placeholder: String,
            text: Binding<String>,
            isInvalid: Bool = false,
            minHeight: CGFloat = 96
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
                        .foregroundStyle(theme.colors.foreground.opacity(0.4))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(theme.spacing.sm)
            .frame(minHeight: minHeight)
            .background(theme.colors.background)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            .animation(.easeOut(duration: 0.15), value: isFocused)
        }

        private var borderColor: Color {
            if isInvalid { return theme.colors.destructive }
            return isFocused ? theme.colors.primary : theme.colors.border
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
