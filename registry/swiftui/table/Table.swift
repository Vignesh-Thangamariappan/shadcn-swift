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
/// Not built (feature gaps, not styling bugs — out of scope for a value-
/// level parity pass): row selected-state background (`data-[state=selected]:bg-muted`,
/// needs a selection binding this API doesn't have), `TableFooter`
/// (`border-t bg-muted/50`), `TableCaption` (`text-sm text-muted-foreground`).
public extension UI {
    struct TableColumn: Identifiable {
        public let id = UUID()
        public let title: String

        public init(_ title: String) {
            self.title = title
        }
    }

    struct Table<Row: View>: View {
        @Environment(\.uiTheme) private var theme

        private let columns: [TableColumn]
        private let rowCount: Int
        private let row: (Int) -> Row

        public init(columns: [TableColumn], rowCount: Int, @ViewBuilder row: @escaping (Int) -> Row) {
            self.columns = columns
            self.rowCount = rowCount
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

                    if index < rowCount - 1 {
                        UI.Separator()
                    }
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
#endif
