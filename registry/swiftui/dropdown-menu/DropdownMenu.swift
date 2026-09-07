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

public extension UI.DropdownMenu {
    /// Real shadcn's dropdown-menu demo triggers from `<Button
    /// variant="outline">` (verified against the actual
    /// `dropdown-menu-demo.tsx`) — a bare `Text` trigger, which this used to
    /// render, doesn't read as tappable at all. Styled inline to match an
    /// outline button's chrome rather than depending on `UI.Button` itself:
    /// this component's registry dependency list is `[tokens]` only, and
    /// adding a cross-component dependency here is a registry.json change
    /// outside a per-component style fix's scope.
    init(_ title: String, items: [UI.MenuItem]) where Label == AnyView {
        self.init(items: items) {
            AnyView(DropdownMenuOutlineTriggerLabel(title: title))
        }
    }
}

private struct DropdownMenuOutlineTriggerLabel: View {
    @Environment(\.uiTheme) private var theme
    let title: String

    var body: some View {
        Text(title)
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.foreground)
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .frame(height: 36)
            .background(theme.colors.background)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                    .strokeBorder(theme.colors.input, lineWidth: 1)
            )
            .uiShadow(theme.shadow.xs)
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
