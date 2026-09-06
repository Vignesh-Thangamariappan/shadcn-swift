import SwiftUI

/// shadcn-swift component: pagination
/// depends on: tokens
public extension UI {
    struct Pagination: View {
        @Environment(\.uiTheme) private var theme

        @Binding private var page: Int
        private let totalPages: Int

        public init(page: Binding<Int>, totalPages: Int) {
            self._page = page
            self.totalPages = totalPages
        }

        public var body: some View {
            HStack(spacing: theme.spacing.xs) {
                navButton(systemImage: "chevron.left", enabled: page > 1) { page -= 1 }

                ForEach(Array(pageNumbers.enumerated()), id: \.offset) { _, number in
                    if number == nil {
                        Text("…")
                            .foregroundStyle(theme.colors.mutedForeground)
                            .frame(width: 32, height: 32)
                    } else {
                        pageButton(number!)
                    }
                }

                navButton(systemImage: "chevron.right", enabled: page < totalPages) { page += 1 }
            }
        }

        @ViewBuilder
        private func pageButton(_ number: Int) -> some View {
            SwiftUI.Button {
                page = number
            } label: {
                Text("\(number)")
                    .font(theme.typography.label)
                    .frame(width: 32, height: 32)
                    .background(number == page ? theme.colors.primary : .clear)
                    .foregroundStyle(number == page ? theme.colors.primaryForeground : theme.colors.foreground)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous))
            }
            .buttonStyle(.plain)
        }

        @ViewBuilder
        private func navButton(systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
            SwiftUI.Button(action: action) {
                Image(systemName: systemImage)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.colors.foreground)
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.4)
        }

        /// `nil` entries render as an ellipsis. Always shows page 1, the
        /// last page, and a window of one page either side of the current
        /// page, collapsing everything else once there's more than 7 pages.
        private var pageNumbers: [Int?] {
            guard totalPages > 7 else { return totalPages > 0 ? Array(1...totalPages) : [] }

            var pages: [Int?] = [1]
            let windowStart = max(2, page - 1)
            let windowEnd = min(totalPages - 1, page + 1)

            if windowStart > 2 { pages.append(nil) }
            pages.append(contentsOf: (windowStart...windowEnd).map { $0 })
            if windowEnd < totalPages - 1 { pages.append(nil) }
            pages.append(totalPages)

            return pages
        }
    }
}

#if DEBUG
private struct PaginationPreview: View {
    @State private var page = 4

    var body: some View {
        UI.Pagination(page: $page, totalPages: 12)
            .padding()
    }
}

#Preview("Pagination") {
    PaginationPreview()
}
#endif
