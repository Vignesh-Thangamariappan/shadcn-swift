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
            // real shadcn's BreadcrumbList is `gap-1.5` (6px) — doesn't sit
            // on an existing spacing tier (xs=4, sm=8), hardcoded rather than
            // rounding either way.
            HStack(spacing: 6) {
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
                        // real shadcn's separator icon is `size-3.5` (14px)
                        // — was 10.
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(theme.colors.mutedForeground)
                    }
                }
            }
            // real shadcn's BreadcrumbList/Page/Link are all `text-sm` with
            // no font-medium anywhere (only color distinguishes the current
            // page) — was `.label` (medium weight), should be `.body`.
            .font(theme.typography.body)
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
