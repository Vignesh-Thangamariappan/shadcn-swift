import SwiftUI

/// shadcn-swift component: input
/// depends on: tokens
///
/// Deviation: focus is tracked with a LOCAL `@FocusState` inside this view,
/// not exposed to the caller. A `@FocusState` binding declared in a child
/// view does not observe focus driven from a parent, so there is no safe way
/// to accept an external `FocusState<Bool>.Binding` here without forcing
/// every call site onto a specific enum-based focus-field type. If a screen
/// needs programmatic focus (autofocus on appear, focus-next on submit),
/// thread `@FocusState` through that screen and drop to a bare SwiftUI
/// `TextField`/`SecureField` there instead of through `UI.Input`.
public extension UI {
    struct Input: View {
        @Environment(\.uiTheme) private var theme
        @FocusState private var isFocused: Bool

        private let placeholder: String
        @Binding private var text: String
        private let isSecure: Bool
        private let isInvalid: Bool

        public init(
            _ placeholder: String,
            text: Binding<String>,
            isSecure: Bool = false,
            isInvalid: Bool = false
        ) {
            self.placeholder = placeholder
            self._text = text
            self.isSecure = isSecure
            self.isInvalid = isInvalid
        }

        public var body: some View {
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .focused($isFocused)
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.foreground)
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
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
            return isFocused ? theme.colors.ring : theme.colors.input
        }
    }
}

#if DEBUG
private struct InputPreview: View {
    @State private var empty = ""
    @State private var filled = "ada@example.com"
    @State private var invalid = "not-an-email"
    @State private var password = "hunter2"

    var body: some View {
        VStack(spacing: 12) {
            UI.Input("Email", text: $empty)
            UI.Input("Email", text: $filled)
            UI.Input("Email", text: $invalid, isInvalid: true)
            UI.Input("Password", text: $password, isSecure: true)
        }
        .padding()
    }
}

#Preview("Input") {
    InputPreview()
}
#endif
