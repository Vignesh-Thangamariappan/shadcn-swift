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
///
/// `variant`/`size` match real shadcn's `item.tsx` `cva()` block exactly
/// (verified live, not memory): variants `default | outline | muted`,
/// sizes `default | sm`. An earlier version had neither — no border/
/// background option at all, and no horizontal padding (only
/// `.padding(.vertical, theme.spacing.xs)`, real shadcn pads all four
/// sides). Title/subtitle typography were also swapped: real shadcn's
/// `ItemTitle` is `text-sm font-medium` and `ItemDescription` is
/// `text-sm font-normal` — this file had `.body` (regular) on the title
/// and `.label` (medium) on the subtitle, backwards from upstream.
public extension UI {
    enum ItemVariant {
        case `default`, outline, muted
    }

    enum ItemSize {
        case `default`, sm
    }

    struct Item<Leading: View, Trailing: View>: View {
        @Environment(\.uiTheme) private var theme

        private let title: String
        private let subtitle: String?
        private let variant: ItemVariant
        private let size: ItemSize
        private let leading: () -> Leading
        private let trailing: () -> Trailing

        public init(
            _ title: String,
            subtitle: String? = nil,
            variant: ItemVariant = .default,
            size: ItemSize = .default,
            @ViewBuilder leading: @escaping () -> Leading,
            @ViewBuilder trailing: @escaping () -> Trailing
        ) {
            self.title = title
            self.subtitle = subtitle
            self.variant = variant
            self.size = size
            self.leading = leading
            self.trailing = trailing
        }

        public var body: some View {
            HStack(spacing: theme.spacing.lg) {
                leading()

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.typography.label)
                        .foregroundStyle(theme.colors.foreground)
                    if let subtitle {
                        Text(subtitle)
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.mutedForeground)
                    }
                }

                Spacer()

                trailing()
            }
            .padding(.horizontal, theme.spacing.lg)
            // real shadcn's `sm` size is `gap-2.5`/`py-3` (10px/12px) — no
            // existing token lands on 10px exactly, `sm` (8) is the nearest.
            .padding(.vertical, size == .sm ? theme.spacing.sm : theme.spacing.lg)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                    .strokeBorder(variant == .outline ? theme.colors.border : .clear, lineWidth: 1)
            )
        }

        private var background: Color {
            switch variant {
            case .default: .clear
            case .outline: .clear
            case .muted: theme.colors.muted.opacity(0.5)
            }
        }
    }
}

public extension UI.Item where Leading == EmptyView, Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil, variant: UI.ItemVariant = .default, size: UI.ItemSize = .default) {
        self.init(title, subtitle: subtitle, variant: variant, size: size, leading: { EmptyView() }, trailing: { EmptyView() })
    }
}

public extension UI.Item where Leading == EmptyView {
    init(_ title: String, subtitle: String? = nil, variant: UI.ItemVariant = .default, size: UI.ItemSize = .default, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.init(title, subtitle: subtitle, variant: variant, size: size, leading: { EmptyView() }, trailing: trailing)
    }
}

public extension UI.Item where Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil, variant: UI.ItemVariant = .default, size: UI.ItemSize = .default, @ViewBuilder leading: @escaping () -> Leading) {
        self.init(title, subtitle: subtitle, variant: variant, size: size, leading: leading, trailing: { EmptyView() })
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
