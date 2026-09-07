import SwiftUI

/// shadcn-swift component: select
/// depends on: tokens
///
/// Self-contained View, not a modifier: SwiftUI's Picker already owns its
/// own presentation (menu overlay, positioning, dismissal) — no portal
/// problem to solve, so this fits the plain-View pattern every other
/// component here uses.
public extension UI {
    struct Select<Option: Hashable>: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.isEnabled) private var isEnabled

        private let options: [Option]
        private let label: (Option) -> String
        @Binding private var selection: Option

        public init(
            selection: Binding<Option>,
            options: [Option],
            label: @escaping (Option) -> String
        ) {
            self._selection = selection
            self.options = options
            self.label = label
        }

        public var body: some View {
            Picker(selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(label(option)).tag(option)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.menu)
            .tint(theme.colors.foreground)
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .frame(height: 36) // real shadcn's default-size trigger is `h-9` (36px), same convention as UI.Button's hardcoded heights
            // real shadcn's trigger is `bg-transparent` in light mode, `dark:bg-input/30` in dark —
            // not the opaque `bg-background` this used to render.
            .background(colorScheme == .dark ? theme.colors.input.opacity(0.3) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                    .strokeBorder(theme.colors.input, lineWidth: 1)
            )
            .uiShadow(theme.shadow.xs) // real shadcn's trigger has `shadow-xs`
            .opacity(isEnabled ? 1 : 0.5) // real shadcn: `disabled:opacity-50` — previously unhandled
        }
    }
}

#if DEBUG
private struct SelectPreview: View {
    @State private var plan = "pro"

    var body: some View {
        UI.Select(selection: $plan, options: ["free", "pro", "team"]) { $0.capitalized }
            .padding()
    }
}

#Preview("Select") {
    SelectPreview()
}
#endif
