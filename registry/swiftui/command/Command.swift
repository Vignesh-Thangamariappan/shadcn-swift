import SwiftUI

/// shadcn-swift component: command
/// depends on: tokens, kbd
///
/// Modifier-shaped, not a self-contained View like select/combobox: a
/// command palette is triggered from anywhere in an app (a toolbar button,
/// a keyboard shortcut on a Mac Catalyst/iPad build), not from one
/// specific view's own tap the way Combobox's trigger button is
/// self-contained. Same `ui`-prefixed external-Binding<Bool> shape as
/// uiSheet/uiDialog.
public extension UI {
    struct CommandItem: Identifiable {
        public let id = UUID()
        public let title: String
        public let systemImage: String?
        public let shortcut: String?
        public let action: () -> Void

        public init(
            _ title: String,
            systemImage: String? = nil,
            shortcut: String? = nil,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.systemImage = systemImage
            self.shortcut = shortcut
            self.action = action
        }
    }

    struct CommandGroup {
        public let title: String?
        public let items: [CommandItem]

        public init(_ title: String? = nil, items: [CommandItem]) {
            self.title = title
            self.items = items
        }
    }

    struct CommandContent: View {
        @Environment(\.uiTheme) private var theme
        @State private var query = ""

        let groups: [CommandGroup]
        let onSelect: () -> Void

        public var body: some View {
            NavigationStack {
                List {
                    ForEach(Array(filteredGroups.enumerated()), id: \.offset) { _, group in
                        Section(group.title ?? "") {
                            ForEach(group.items) { item in
                                SwiftUI.Button {
                                    item.action()
                                    onSelect()
                                } label: {
                                    HStack {
                                        if let systemImage = item.systemImage {
                                            Image(systemName: systemImage)
                                                .foregroundStyle(theme.colors.mutedForeground)
                                        }
                                        Text(item.title)
                                            .foregroundStyle(theme.colors.foreground)
                                        Spacer()
                                        if let shortcut = item.shortcut {
                                            UI.Kbd(shortcut)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .searchable(text: $query)
                .navigationTitle("Command Menu")
                .navigationBarTitleDisplayMode(.inline)
            }
        }

        private var filteredGroups: [CommandGroup] {
            guard !query.isEmpty else { return groups }
            return groups.compactMap { group in
                let matches = group.items.filter { $0.title.localizedCaseInsensitiveContains(query) }
                return matches.isEmpty ? nil : CommandGroup(group.title, items: matches)
            }
        }
    }
}

public extension View {
    func uiCommand(isPresented: Binding<Bool>, groups: [UI.CommandGroup]) -> some View {
        sheet(isPresented: isPresented) {
            UI.CommandContent(groups: groups, onSelect: { isPresented.wrappedValue = false })
                .presentationDetents([.medium, .large])
        }
    }
}

#if DEBUG
private struct CommandPreview: View {
    @State private var isPresented = false

    var body: some View {
        Text("Host content")
            .uiCommand(isPresented: $isPresented, groups: [
                UI.CommandGroup("Suggestions", items: [
                    UI.CommandItem("New file", systemImage: "doc.badge.plus", shortcut: "⌘N", action: {}),
                    UI.CommandItem("Search", systemImage: "magnifyingglass", shortcut: "⌘K", action: {})
                ]),
                UI.CommandGroup("Settings", items: [
                    UI.CommandItem("Preferences", systemImage: "gearshape", action: {})
                ])
            ])
            .onAppear { isPresented = true }
    }
}

#Preview("Command") {
    CommandPreview()
}
#endif
