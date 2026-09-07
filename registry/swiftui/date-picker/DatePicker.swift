import SwiftUI

/// shadcn-swift component: date-picker
/// depends on: tokens, calendar
///
/// Real shadcn's date-picker is literally Popover + Calendar + a trigger
/// button showing the formatted date — this is that, nearly free now that
/// UI.Calendar exists. Self-contained (owns its own `@State isPresented`
/// and a bare native `.popover`, not the `uiPopover` modifier) for the same
/// reason UI.Combobox bypasses `uiSheet`: UI.Calendar already themes its
/// own surface, so wrapping it in another themed popover container would
/// double up backgrounds. `.presentationCompactAdaptation(.popover)` is
/// still here, though — same reason it's load-bearing in uiPopover itself.
public extension UI {
    struct DatePicker: View {
        @Environment(\.uiTheme) private var theme
        @State private var isPresented = false

        private let placeholder: String
        @Binding private var selection: Date?
        private let isDateDisabled: (Date) -> Bool

        public init(
            _ placeholder: String = "Pick a date",
            selection: Binding<Date?>,
            isDateDisabled: @escaping (Date) -> Bool = { _ in false }
        ) {
            self.placeholder = placeholder
            self._selection = selection
            self.isDateDisabled = isDateDisabled
        }

        public var body: some View {
            SwiftUI.Button {
                isPresented = true
            } label: {
                HStack {
                    Image(systemName: "calendar")
                    Text(selection.map(Self.formatted) ?? placeholder)
                        .foregroundStyle(selection == nil ? theme.colors.mutedForeground : theme.colors.foreground)
                    Spacer()
                }
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
                // real shadcn's Button `outline` variant is `border
                // bg-background shadow-xs` — height `h-9` (36px). This was
                // missing the shadow and not enforcing a fixed height.
                .frame(minHeight: 36)
                .background(theme.colors.background)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                        .strokeBorder(theme.colors.input, lineWidth: 1)
                )
                .uiShadow(theme.shadow.xs)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.colors.foreground)
            .popover(isPresented: $isPresented) {
                UI.Calendar(selection: $selection, isDateDisabled: isDateDisabled)
                    .presentationCompactAdaptation(.popover)
                    .onChange(of: selection) { _, _ in isPresented = false }
            }
        }

        private static func formatted(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

#if DEBUG
private struct DatePickerPreview: View {
    @State private var date: Date?

    var body: some View {
        UI.DatePicker(selection: $date)
            .padding()
    }
}

#Preview("DatePicker") {
    DatePickerPreview()
}
#endif
