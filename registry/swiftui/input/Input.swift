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
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.colorScheme) private var colorScheme
        @FocusState private var isFocused: Bool

        private let placeholder: String
        @Binding private var text: String
        private let isSecure: Bool
        private let isInvalid: Bool
        private let shape: UI.Theme.CornerStyle?

        public init(
            _ placeholder: String,
            text: Binding<String>,
            isSecure: Bool = false,
            isInvalid: Bool = false,
            shape: UI.Theme.CornerStyle? = nil
        ) {
            self.placeholder = placeholder
            self._text = text
            self.isSecure = isSecure
            self.isInvalid = isInvalid
            self.shape = shape
        }

        // `shape: .full` mirrors real shadcn's `className="rounded-full"`
        // override — see `Button.swift`'s header for why this needs to be a
        // real parameter rather than a second `.clipShape` from outside.
        private var cornerRadius: CGFloat {
            (shape ?? .radius(theme.radius.md)).cornerRadius
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
            .frame(height: 36) // real shadcn's `h-9`
            .background(fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            .uiShadow(theme.shadow.xs)
            .opacity(isEnabled ? 1 : 0.5)
            // Real shadcn's focus transition is `transition-[color,box-shadow]`
            // — Tailwind's default curve is ease-in-out, not ease-out (verified
            // against `tailwindlabs/tailwindcss`'s own theme.css, same fix
            // already applied to InputGroup.swift for the identical mismatch).
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }

        private var borderColor: Color {
            if isInvalid { return theme.colors.destructive }
            return isFocused ? theme.colors.ring : theme.colors.input
        }

        // Real shadcn is `bg-transparent` in light mode, `dark:bg-input/30`
        // in dark — not a flat `background` fill in both, which would hide
        // the field against most surfaces it sits on.
        private var fieldBackground: Color {
            colorScheme == .dark ? theme.colors.input.opacity(0.3) : .clear
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
