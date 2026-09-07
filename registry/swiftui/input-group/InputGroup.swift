import SwiftUI

/// shadcn-swift component: input-group
/// depends on: tokens
///
/// UI.Input with a leading/trailing icon or button slot — a search field
/// with a magnifying glass, an amount field with a trailing "Max" button,
/// etc. A separate component rather than adding slots to UI.Input itself:
/// the plain Input stays the common case with a simple signature, and this
/// covers the compositional one, same split shadcn itself draws between
/// Input and InputGroup.
///
/// Gotcha: when supplying only ONE slot, use an explicit `leading:`/
/// `trailing:` argument label rather than a bare trailing closure — with
/// no label, the compiler can't tell which single-slot initializer you
/// mean and reports "ambiguous use of init".
///
/// Real shadcn's `input-group.tsx` container carries `shadow-xs` — missing
/// here before `theme.shadow.xs` existed to reference (added in this
/// repo's own token-foundation pass); now applied via `.uiShadow(_:)`.
public extension UI {
    struct InputGroup<Leading: View, Trailing: View>: View {
        @Environment(\.uiTheme) private var theme
        @FocusState private var isFocused: Bool

        private let placeholder: String
        @Binding private var text: String
        private let isInvalid: Bool
        private let shape: UI.Theme.CornerStyle?
        private let leading: () -> Leading
        private let trailing: () -> Trailing

        public init(
            _ placeholder: String,
            text: Binding<String>,
            isInvalid: Bool = false,
            shape: UI.Theme.CornerStyle? = nil,
            @ViewBuilder leading: @escaping () -> Leading,
            @ViewBuilder trailing: @escaping () -> Trailing
        ) {
            self.placeholder = placeholder
            self._text = text
            self.isInvalid = isInvalid
            self.shape = shape
            self.leading = leading
            self.trailing = trailing
        }

        // `shape: .full` mirrors real shadcn's `className="rounded-full"`
        // override — see `Button.swift`'s header for why this needs to be a
        // real parameter rather than a second `.clipShape` from outside.
        private var cornerRadius: CGFloat {
            (shape ?? .radius(theme.radius.md)).cornerRadius
        }

        public var body: some View {
            HStack(spacing: theme.spacing.sm) {
                leading()
                    .foregroundStyle(theme.colors.mutedForeground)

                TextField(placeholder, text: $text)
                    .focused($isFocused)

                trailing()
                    .foregroundStyle(theme.colors.mutedForeground)
            }
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.foreground)
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .background(theme.colors.background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            .uiShadow(theme.shadow.xs)
            // real shadcn's focus transition is `transition-[color,box-shadow]` —
            // Tailwind's default duration/curve (150ms, ease-in-out), verified
            // against `tailwindlabs/tailwindcss`'s own theme.css. Duration was
            // already right; curve was `.easeOut`, not `.easeInOut`.
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }

        private var borderColor: Color {
            if isInvalid { return theme.colors.destructive }
            return isFocused ? theme.colors.ring : theme.colors.input
        }
    }
}

public extension UI.InputGroup where Trailing == EmptyView {
    init(
        _ placeholder: String,
        text: Binding<String>,
        isInvalid: Bool = false,
        shape: UI.Theme.CornerStyle? = nil,
        @ViewBuilder leading: @escaping () -> Leading
    ) {
        self.init(placeholder, text: text, isInvalid: isInvalid, shape: shape, leading: leading, trailing: { EmptyView() })
    }
}

public extension UI.InputGroup where Leading == EmptyView {
    init(
        _ placeholder: String,
        text: Binding<String>,
        isInvalid: Bool = false,
        shape: UI.Theme.CornerStyle? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.init(placeholder, text: text, isInvalid: isInvalid, shape: shape, leading: { EmptyView() }, trailing: trailing)
    }
}

#if DEBUG
private struct InputGroupPreview: View {
    @State private var search = ""
    @State private var amount = ""

    var body: some View {
        VStack(spacing: 12) {
            UI.InputGroup("Search", text: $search, leading: {
                Image(systemName: "magnifyingglass")
            })
            UI.InputGroup("0.00", text: $amount, trailing: {
                SwiftUI.Button("Max") {}
                    .font(.caption)
            })
        }
        .padding()
    }
}

#Preview("InputGroup") {
    InputGroupPreview()
}
#endif
