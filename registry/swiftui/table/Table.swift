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
                            .foregroundStyle(theme.colors.mutedForeground)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, theme.spacing.sm)

                UI.Separator()

                ForEach(0..<rowCount, id: \.self) { index in
                    row(index)
                        .padding(.vertical, theme.spacing.sm)

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
