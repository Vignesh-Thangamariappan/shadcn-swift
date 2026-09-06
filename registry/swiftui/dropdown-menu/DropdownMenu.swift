import SwiftUI

/// shadcn-swift component: dropdown-menu
/// depends on: tokens
///
/// Self-contained View, not a modifier: SwiftUI's Menu already owns its own
/// presentation — no portal problem here. `UI.MenuItem` is defined here and
/// reused by context-menu (which depends on this component for the type).
public extension UI {
    struct MenuItem: Identifiable {
        public let id = UUID()
        public let title: String
        public let systemImage: String?
        public let isDestructive: Bool
        public let action: () -> Void

        public init(
            _ title: String,
            systemImage: String? = nil,
            isDestructive: Bool = false,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.systemImage = systemImage
            self.isDestructive = isDestructive
            self.action = action
        }
    }

    struct DropdownMenu<Label: View>: View {
        private let items: [MenuItem]
        private let label: () -> Label

        public init(items: [MenuItem], @ViewBuilder label: @escaping () -> Label) {
            self.items = items
            self.label = label
        }

        public var body: some View {
            Menu {
                ForEach(items) { item in
                    SwiftUI.Button(role: item.isDestructive ? .destructive : nil, action: item.action) {
                        if let systemImage = item.systemImage {
                            SwiftUI.Label(item.title, systemImage: systemImage)
                        } else {
                            Text(item.title)
                        }
                    }
                }
            } label: {
                label()
            }
        }
    }
}

public extension UI.DropdownMenu where Label == Text {
    init(_ title: String, items: [UI.MenuItem]) {
        self.init(items: items) { Text(title) }
    }
}

#if DEBUG
private struct DropdownMenuPreview: View {
    var body: some View {
        UI.DropdownMenu("Options", items: [
            UI.MenuItem("Edit", systemImage: "pencil", action: {}),
            UI.MenuItem("Share", systemImage: "square.and.arrow.up", action: {}),
            UI.MenuItem("Delete", systemImage: "trash", isDestructive: true, action: {})
        ])
        .padding()
    }
}

#Preview("DropdownMenu") {
    DropdownMenuPreview()
}
#endif
