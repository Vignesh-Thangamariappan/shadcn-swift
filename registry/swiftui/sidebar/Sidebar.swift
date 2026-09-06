import SwiftUI

/// shadcn-swift component: sidebar
/// depends on: tokens
///
/// iPad-shaped, not iPhone-shaped — the one platform-gap component that
/// got reconsidered rather than skipped. Wraps native `NavigationSplitView`,
/// which already owns adaptive collapse behavior: a persistent
/// always-visible column on iPad's regular width class, a normal
/// push-navigation stack on iPhone's compact width. Reimplementing that
/// collapse logic by hand would just be worse than what Apple already
/// ships — same reasoning `select`/`dropdown-menu` wrap native controls
/// instead of rebuilding them.
///
/// shadcn's own Sidebar is fundamentally the same idea (a persistent desktop
/// nav rail, with a mobile sheet fallback) — this component's PURPOSE, an
/// always-visible nav rail, is a regular-width-class (iPad) pattern. On
/// iPhone it degrades to a normal navigation flow automatically, which is
/// the correct native behavior there, not a missing feature.
///
/// Scope: single-level navigation — one flat list of items, one detail
/// pane. shadcn's Sidebar also supports nested/collapsible groups
/// (SidebarGroup/SidebarMenuSub) — not built here.
///
/// Same shadowing family as UI.Button/UI.Calendar/UI.Chart: this file sits
/// inside `extension UI`, which already has its own `UI.Label` (the
/// registry's `label` component, a single-String initializer). An
/// unqualified `Label(title, systemImage:)` here would resolve to that
/// enclosing `UI.Label` instead of `SwiftUI.Label` — qualified explicitly
/// below for that reason.
public extension UI {
    struct SidebarItem: Identifiable, Hashable {
        public let id: String
        public let title: String
        public let systemImage: String

        public init(_ id: String, title: String, systemImage: String) {
            self.id = id
            self.title = title
            self.systemImage = systemImage
        }
    }

    struct Sidebar<Detail: View>: View {
        @Environment(\.uiTheme) private var theme

        private let title: String
        private let items: [SidebarItem]
        @Binding private var selection: SidebarItem.ID?
        private let detail: (SidebarItem.ID?) -> Detail

        public init(
            _ title: String = "",
            items: [SidebarItem],
            selection: Binding<SidebarItem.ID?>,
            @ViewBuilder detail: @escaping (SidebarItem.ID?) -> Detail
        ) {
            self.title = title
            self.items = items
            self._selection = selection
            self.detail = detail
        }

        public var body: some View {
            NavigationSplitView {
                List(items, selection: $selection) { item in
                    SwiftUI.Label(item.title, systemImage: item.systemImage)
                }
                .listStyle(.sidebar)
                .navigationTitle(title)
            } detail: {
                detail(selection)
            }
            .tint(theme.colors.primary)
        }
    }
}

#if DEBUG
private struct SidebarPreview: View {
    @State private var selection: UI.SidebarItem.ID?

    private let items = [
        UI.SidebarItem("inbox", title: "Inbox", systemImage: "tray"),
        UI.SidebarItem("sent", title: "Sent", systemImage: "paperplane"),
        UI.SidebarItem("settings", title: "Settings", systemImage: "gearshape")
    ]

    var body: some View {
        UI.Sidebar("Mail", items: items, selection: $selection) { selected in
            if let selected {
                Text("Detail for \(selected)")
            } else {
                Text("Select an item")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Sidebar") {
    SidebarPreview()
}
#endif
