import SwiftUI

/// shadcn-swift component: table
/// depends on: tokens, separator
///
/// This is shadcn's plain `table` — a styled header row + body rows, no
/// sorting/filtering/pagination. That's `data-table` (built on TanStack
/// Table upstream), and it's a genuinely different scale of component:
/// sort state, filter state, column visibility, per-column custom
/// renderers. Deliberately NOT built here — it deserves its own design
/// pass when a real screen needs it, not a half-built version bolted onto
/// this file. See the README's coverage-gap notes.
///
/// Column headers are just labels; each row's cell layout is the caller's
/// own view (same content-closure shape as UI.Tabs/UI.Accordion) so a row
/// can lay out cells however its data actually needs — this component
/// only owns the header row and the separators between rows.
///
/// Header text is `theme.colors.foreground` (real shadcn's `TableHead` is
/// `text-foreground`) — an earlier version used `mutedForeground`, which is
/// real shadcn's `TableCaption` color, not the header's. Cell/header padding
/// is `theme.spacing.sm` on both axes (real: `p-2`/`px-2`) — an earlier
/// version only padded vertically.
///
/// `isRowSelected`, `caption`, and `footer` close the three gaps a value-level
/// parity pass previously left open (real shadcn's `data-[state=selected]:bg-muted`,
/// `TableCaption`, `TableFooter` — verified against the live `table.tsx`
/// source). All three are additive and default to "off", so every existing
/// call site keeps compiling and rendering unchanged. `isRowSelected` is a
/// plain per-index visual toggle the caller supplies — same as real shadcn's
/// own `data-state` attribute, this component doesn't manage selection state
/// itself, matching `data-table`'s state machinery being explicitly out of
/// scope here.
public extension UI {
    struct TableColumn: Identifiable {
        public let id = UUID()
        public let title: String

        public init(_ title: String) {
            self.title = title
        }
    }

    struct Table<Row: View, Footer: View>: View {
        @Environment(\.uiTheme) private var theme

        private let columns: [TableColumn]
        private let rowCount: Int
        private let isRowSelected: (Int) -> Bool
        private let caption: String?
        private let footer: () -> Footer
        private let row: (Int) -> Row

        public init(
            columns: [TableColumn],
            rowCount: Int,
            isRowSelected: @escaping (Int) -> Bool = { _ in false },
            caption: String? = nil,
            @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
            @ViewBuilder row: @escaping (Int) -> Row
        ) {
            self.columns = columns
            self.rowCount = rowCount
            self.isRowSelected = isRowSelected
            self.caption = caption
            self.footer = footer
            self.row = row
        }

        public var body: some View {
            VStack(spacing: 0) {
                HStack(spacing: theme.spacing.sm) {
                    ForEach(columns) { column in
                        Text(column.title)
                            .font(theme.typography.label)
                            .foregroundStyle(theme.colors.foreground)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(theme.spacing.sm)

                UI.Separator()

                ForEach(0..<rowCount, id: \.self) { index in
                    row(index)
                        .padding(theme.spacing.sm)
                        // real shadcn: `data-[state=selected]:bg-muted`
                        .background(isRowSelected(index) ? theme.colors.muted : .clear)

                    if index < rowCount - 1 {
                        UI.Separator()
                    }
                }

                // `Footer.self != EmptyView.self` is how this detects "was a
                // footer actually provided" — the default closure makes
                // `Footer` infer to `EmptyView` at call sites that omit it,
                // so nothing renders (no stray border/tint) when there's no
                // footer content.
                if Footer.self != EmptyView.self {
                    UI.Separator()
                    footer()
                        .font(theme.typography.label) // real shadcn: `font-medium` at inherited text-sm
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(theme.spacing.sm)
                        .background(theme.colors.muted.opacity(0.5)) // real shadcn: `bg-muted/50`
                }

                if let caption {
                    Text(caption)
                        .font(theme.typography.body) // real shadcn: `text-sm`
                        .foregroundStyle(theme.colors.mutedForeground)
                        .padding(.top, theme.spacing.lg) // real shadcn: `mt-4` = 16pt
                }
            }
        }
    }
}

#if DEBUG
private struct TablePreview: View {
    private let rows = [
        ("Ada Lovelace", "Engineering", "Active"),
        ("Grace Hopper", "Engineering", "Active"),
        ("Alan Turing", "Research", "On leave")
    ]

    var body: some View {
        UI.Table(
            columns: [UI.TableColumn("Name"), UI.TableColumn("Team"), UI.TableColumn("Status")],
            rowCount: 3
        ) { index in
            let row = rows[index]
            HStack(spacing: 12) {
                Text(row.0).frame(maxWidth: .infinity, alignment: .leading)
                Text(row.1).frame(maxWidth: .infinity, alignment: .leading)
                Text(row.2).frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.subheadline)
        }
        .padding()
    }
}

#Preview("Table") {
    TablePreview()
}

private struct TableWithFooterAndCaptionPreview: View {
    private let rows = [
        ("Invoice #1", "Paid", "$250.00"),
        ("Invoice #2", "Pending", "$150.00"),
        ("Invoice #3", "Paid", "$350.00")
    ]

    var body: some View {
        UI.Table(
            columns: [UI.TableColumn("Invoice"), UI.TableColumn("Status"), UI.TableColumn("Amount")],
            rowCount: 3,
            isRowSelected: { $0 == 1 },
            caption: "A list of your recent invoices.",
            footer: {
                HStack {
                    Text("Total")
                    Spacer()
                    Text("$750.00")
                }
            }
        ) { index in
            let row = rows[index]
            HStack(spacing: 12) {
                Text(row.0).frame(maxWidth: .infinity, alignment: .leading)
                Text(row.1).frame(maxWidth: .infinity, alignment: .leading)
                Text(row.2).frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.subheadline)
        }
        .padding()
    }
}

#Preview("Table with footer, caption, selected row") {
    TableWithFooterAndCaptionPreview()
}
#endif
