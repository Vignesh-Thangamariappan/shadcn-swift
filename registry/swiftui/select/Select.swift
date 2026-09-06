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
            .background(theme.colors.background)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                    .strokeBorder(theme.colors.border, lineWidth: 1)
            )
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
