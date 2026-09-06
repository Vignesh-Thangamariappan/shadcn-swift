import SwiftUI

/// shadcn-swift component: breadcrumb
/// depends on: tokens
public extension UI {
    struct BreadcrumbItem: Identifiable {
        public let id = UUID()
        public let title: String
        public let action: (() -> Void)?

        public init(_ title: String, action: (() -> Void)? = nil) {
            self.title = title
            self.action = action
        }
    }

    struct Breadcrumb: View {
        @Environment(\.uiTheme) private var theme

        private let items: [BreadcrumbItem]

        public init(_ items: [BreadcrumbItem]) {
            self.items = items
        }

        public var body: some View {
            HStack(spacing: theme.spacing.xs) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if let action = item.action {
                        SwiftUI.Button(action: action) {
                            Text(item.title)
                                .foregroundStyle(theme.colors.mutedForeground)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(item.title)
                            .foregroundStyle(theme.colors.foreground)
                    }

                    if index < items.count - 1 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundStyle(theme.colors.mutedForeground)
                    }
                }
            }
            .font(theme.typography.label)
        }
    }
}

#if DEBUG
private struct BreadcrumbPreview: View {
    var body: some View {
        UI.Breadcrumb([
            UI.BreadcrumbItem("Home", action: {}),
            UI.BreadcrumbItem("Settings", action: {}),
            UI.BreadcrumbItem("Profile")
        ])
        .padding()
    }
}

#Preview("Breadcrumb") {
    BreadcrumbPreview()
}
#endif
