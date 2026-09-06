import SwiftUI

/// shadcn-swift component: tabs
/// depends on: tokens
public extension UI {
    struct Tabs<Tag: Hashable, Content: View>: View {
        @Environment(\.uiTheme) private var theme

        private let items: [(tag: Tag, title: String)]
        @Binding private var selection: Tag
        private let content: (Tag) -> Content

        public init(
            items: [(tag: Tag, title: String)],
            selection: Binding<Tag>,
            @ViewBuilder content: @escaping (Tag) -> Content
        ) {
            self.items = items
            self._selection = selection
            self.content = content
        }

        public var body: some View {
            VStack(spacing: theme.spacing.md) {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(items, id: \.tag) { item in
                        SwiftUI.Button {
                            selection = item.tag
                        } label: {
                            Text(item.title)
                                .font(theme.typography.label)
                                .padding(.horizontal, theme.spacing.md)
                                .padding(.vertical, theme.spacing.sm)
                                .frame(maxWidth: .infinity)
                                .background(item.tag == selection ? theme.colors.background : .clear)
                                .foregroundStyle(
                                    item.tag == selection
                                        ? theme.colors.foreground
                                        : theme.colors.foreground.opacity(0.6)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(theme.spacing.xs / 2)
                .background(theme.colors.secondary)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))

                content(selection)
            }
        }
    }
}

#if DEBUG
private struct TabsPreview: View {
    @State private var tab = "profile"

    var body: some View {
        UI.Tabs(
            items: [(tag: "profile", title: "Profile"), (tag: "settings", title: "Settings")],
            selection: $tab
        ) { selected in
            Text("Content for \(selected)")
        }
        .padding()
    }
}

#Preview("Tabs") {
    TabsPreview()
}
#endif
