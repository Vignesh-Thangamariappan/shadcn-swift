import SwiftUI

/// shadcn-swift component: tabs
/// depends on: tokens
///
/// Corner radius: outer `TabsList` container is `theme.radius.lg` (real
/// shadcn: `rounded-lg`), the active `TabsTrigger` pill inside it is
/// `theme.radius.md` (real shadcn: `rounded-md`) — two different tiers, not
/// the same one. An earlier version had them backwards (`md` outer, `sm`
/// inner).
///
/// List background is `theme.colors.muted` (real shadcn: `bg-muted`) — an
/// earlier version used `secondary`, the wrong token for this literal class.
/// The list itself has no item-to-item gap (real shadcn's default-variant
/// `TabsList` has no `gap-*` class; separation comes purely from each
/// trigger's own padding) and `p-[3px]` padding, hardcoded here since 3px
/// doesn't land on any spacing tier. The active trigger gets `theme.shadow.sm`
/// (real: `data-[state=active]:shadow-sm`) — missing before. Root-to-content
/// spacing is `theme.spacing.sm` (real shadcn's `Tabs` root is `gap-2` = 8px),
/// not `md` (12px), which an earlier version used.
///
/// Not replicated: real shadcn's active tab gets a translucent `bg-input/30`
/// tint and an `input`-colored border in DARK mode specifically (light mode
/// is a plain `background` fill with a transparent border, which this DOES
/// match). Reproducing the dark-only variant would need per-color-scheme
/// branching this component doesn't otherwise have — flagged, not fixed.
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
            VStack(spacing: theme.spacing.sm) {
                HStack(spacing: 0) {
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
                                .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
                                .uiShadow(item.tag == selection ? theme.shadow.sm : .init(color: .clear, radius: 0, y: 0))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(theme.colors.muted)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
                // Real shadcn's trigger has `transition-all` — Tailwind's
                // default is 150ms `cubic-bezier(0.4,0,0.2,1)` (verified
                // against `tailwindlabs/tailwindcss`'s own theme.css), which
                // `.timingCurve` reproduces exactly rather than approximating
                // with a named curve. Without this, the active pill's
                // background/shadow snapped instantly on tab change.
                .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.15), value: selection)

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
