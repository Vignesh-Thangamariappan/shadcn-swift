import SwiftUI

/// shadcn-swift component: item
/// depends on: tokens, separator (preview only — the type itself needs
/// nothing beyond tokens, separator just demonstrates the common "rows in
/// a list" call pattern)
///
/// Generic list-row composition — leading content, title/subtitle,
/// trailing content — same shape shadcn's Item covers for settings rows,
/// contact rows, notification rows, etc. Leading/trailing default to
/// EmptyView via the constrained convenience initializers below, so a
/// call site only supplies what it actually needs.
///
/// Gotcha: when supplying only ONE slot, use an explicit `leading:`/
/// `trailing:` argument label rather than a bare trailing closure — with
/// no label, the compiler can't tell which single-slot initializer you
/// mean and reports "ambiguous use of init".
public extension UI {
    struct Item<Leading: View, Trailing: View>: View {
        @Environment(\.uiTheme) private var theme

        private let title: String
        private let subtitle: String?
        private let leading: () -> Leading
        private let trailing: () -> Trailing

        public init(
            _ title: String,
            subtitle: String? = nil,
            @ViewBuilder leading: @escaping () -> Leading,
            @ViewBuilder trailing: @escaping () -> Trailing
        ) {
            self.title = title
            self.subtitle = subtitle
            self.leading = leading
            self.trailing = trailing
        }

        public var body: some View {
            HStack(spacing: theme.spacing.md) {
                leading()

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.foreground)
                    if let subtitle {
                        Text(subtitle)
                            .font(theme.typography.label)
                            .foregroundStyle(theme.colors.mutedForeground)
                    }
                }

                Spacer()

                trailing()
            }
            .padding(.vertical, theme.spacing.xs)
        }
    }
}

public extension UI.Item where Leading == EmptyView, Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil) {
        self.init(title, subtitle: subtitle, leading: { EmptyView() }, trailing: { EmptyView() })
    }
}

public extension UI.Item where Leading == EmptyView {
    init(_ title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.init(title, subtitle: subtitle, leading: { EmptyView() }, trailing: trailing)
    }
}

public extension UI.Item where Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil, @ViewBuilder leading: @escaping () -> Leading) {
        self.init(title, subtitle: subtitle, leading: leading, trailing: { EmptyView() })
    }
}

#if DEBUG
private struct ItemPreview: View {
    var body: some View {
        VStack(spacing: 0) {
            UI.Item("Plain row, no slots")
            UI.Separator()
            UI.Item("Notifications", subtitle: "Push, email, SMS", leading: {
                Image(systemName: "bell")
            })
            UI.Separator()
            UI.Item("Wi-Fi", subtitle: "Connected") {
                Image(systemName: "wifi")
            } trailing: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

#Preview("Item") {
    ItemPreview()
}
#endif
