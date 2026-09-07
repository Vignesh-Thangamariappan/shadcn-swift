import SwiftUI

/// shadcn-swift component: accordion
/// depends on: tokens, separator
///
/// Same shape as UI.Tabs (items + a per-tag content closure) rather than
/// an array of pre-built AccordionItem<Content> structs — that would force
/// every item in one Accordion to share a single Content type anyway, so
/// the closure form is no less flexible and avoids a second generic
/// item-model type. `allowsMultipleExpanded: false` (shadcn's "single"
/// type) collapses any other open item when one opens; `true` (shadcn's
/// "multiple") leaves them independent.
///
/// Trigger vertical padding is `theme.spacing.lg` (real shadcn: `py-4` =
/// 16px) on the trigger row itself, with expanded content getting only
/// bottom padding at the same size (real: `pt-0 pb-4`) — an earlier version
/// put `sm` (8px) padding around the whole trigger+content group instead,
/// which was both the wrong size and applied to the wrong element. The
/// chevron is `theme.colors.mutedForeground` (real: the icon is explicitly
/// `text-muted-foreground`, NOT inherited from the trigger's own text
/// color) — an earlier version painted it the same `foreground` as the
/// title text, which real shadcn does not do.
public extension UI {
    struct Accordion<Tag: Hashable, Content: View>: View {
        @Environment(\.uiTheme) private var theme

        private let items: [(tag: Tag, title: String)]
        @Binding private var expanded: Set<Tag>
        private let allowsMultipleExpanded: Bool
        private let content: (Tag) -> Content

        public init(
            items: [(tag: Tag, title: String)],
            expanded: Binding<Set<Tag>>,
            allowsMultipleExpanded: Bool = false,
            @ViewBuilder content: @escaping (Tag) -> Content
        ) {
            self.items = items
            self._expanded = expanded
            self.allowsMultipleExpanded = allowsMultipleExpanded
            self.content = content
        }

        public var body: some View {
            VStack(spacing: 0) {
                ForEach(items, id: \.tag) { item in
                    VStack(alignment: .leading, spacing: 0) {
                        SwiftUI.Button {
                            withAnimation(.easeOut(duration: 0.2)) { toggle(item.tag) }
                        } label: {
                            HStack {
                                Text(item.title)
                                    .font(theme.typography.label)
                                    .foregroundStyle(theme.colors.foreground)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(theme.colors.mutedForeground)
                                    .rotationEffect(.degrees(expanded.contains(item.tag) ? 180 : 0))
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, theme.spacing.lg)

                        if expanded.contains(item.tag) {
                            content(item.tag)
                                .padding(.bottom, theme.spacing.lg)
                        }
                    }

                    if item.tag != items.last?.tag {
                        UI.Separator()
                    }
                }
            }
        }

        private func toggle(_ tag: Tag) {
            if expanded.contains(tag) {
                expanded.remove(tag)
            } else if allowsMultipleExpanded {
                expanded.insert(tag)
            } else {
                expanded = [tag]
            }
        }
    }
}

#if DEBUG
private struct AccordionPreview: View {
    @State private var expanded: Set<String> = ["shipping"]

    var body: some View {
        UI.Accordion(
            items: [
                (tag: "shipping", title: "Shipping"),
                (tag: "returns", title: "Returns"),
                (tag: "warranty", title: "Warranty")
            ],
            expanded: $expanded
        ) { tag in
            Text("Content for \(tag)")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview("Accordion") {
    AccordionPreview()
}
#endif
