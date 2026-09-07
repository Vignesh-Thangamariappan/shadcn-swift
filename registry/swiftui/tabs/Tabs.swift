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
/// The active tab is a plain `background` fill with no border in light
/// mode, but real shadcn switches to a translucent `bg-input/30` tint plus
/// an `input`-colored border in DARK mode specifically (same `dark:bg-input/
/// 30` pattern `Button`'s `outline` variant and `Select`'s trigger already
/// use) — that's `activeBackground`/`activeBorder` below, gated on
/// `colorScheme`.
public extension UI {
    struct Tabs<Tag: Hashable, Content: View>: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.colorScheme) private var colorScheme

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
                                .background(item.tag == selection ? activeBackground : .clear)
                                .foregroundStyle(
                                    item.tag == selection
                                        ? theme.colors.foreground
                                        : theme.colors.foreground.opacity(0.6)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                                        .strokeBorder(item.tag == selection ? activeBorder : .clear, lineWidth: 1)
                                )
                                .uiShadow(item.tag == selection ? theme.shadow.sm : .init(color: .clear, radius: 0, y: 0))
                                // Defensive: `.frame(maxWidth: .infinity)` above
                                // should already make the whole cell tappable,
                                // not just the visible label, but a real
                                // consuming app hit this not being reliable in
                                // practice — matching the clip shape exactly
                                // (not a plain full-bleed Rectangle) keeps the
                                // tap area equal to the visual bounds, no more.
                                .contentShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
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

        // Real shadcn's active trigger: `bg-background` / `dark:bg-input/30`.
        private var activeBackground: Color {
            colorScheme == .dark ? theme.colors.input.opacity(0.3) : theme.colors.background
        }

        // Real shadcn: no border in light mode, `dark:border-input`.
        private var activeBorder: Color {
            colorScheme == .dark ? theme.colors.input : .clear
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
