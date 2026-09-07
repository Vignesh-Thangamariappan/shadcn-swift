import SwiftUI

/// shadcn-swift component: pagination
/// depends on: tokens
///
/// Page number buttons use `theme.radius.md`: real shadcn's
/// `PaginationLink` literally renders `buttonVariants({...})` — it IS a
/// Button, `rounded-md` like every other one. An earlier version used
/// `sm`, one tier too tight.
///
/// The active page is `variant="outline"` (bordered, not filled) and every
/// other page is `variant="ghost"` — an earlier version filled the active
/// number with a solid `primary` background, which real shadcn never does.
/// Size is `size="icon"`/`size="default"` (36px), was 32.
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
                        // real shadcn's PaginationEllipsis is `size-9` (36),
                        // was 32.
                        Text("…")
                            .foregroundStyle(theme.colors.mutedForeground)
                            .frame(width: 36, height: 36)
                    } else {
                        pageButton(number!)
                    }
                }

                navButton(systemImage: "chevron.right", enabled: page < totalPages) { page += 1 }
            }
        }

        @ViewBuilder
        private func pageButton(_ number: Int) -> some View {
            let isActive = number == page
            SwiftUI.Button {
                page = number
            } label: {
                Text("\(number)")
                    .font(theme.typography.label)
                    // real shadcn's PaginationLink is `size="icon"` =
                    // `size-9` (36) — was 32.
                    .frame(width: 36, height: 36)
                    // real shadcn's active page is `variant="outline"`
                    // (bordered, NOT filled with primary) and inactive is
                    // `variant="ghost"` (transparent) — was filling the
                    // active number with a solid `theme.colors.primary`
                    // background before, which real shadcn never does.
                    .background(isActive ? theme.colors.background : .clear)
                    .foregroundStyle(theme.colors.foreground)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                            .strokeBorder(isActive ? theme.colors.input : .clear, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
            }
            .buttonStyle(.plain)
        }

        @ViewBuilder
        private func navButton(systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
            SwiftUI.Button(action: action) {
                Image(systemName: systemImage)
                    // real shadcn's Previous/Next are `size="default"`
                    // (`h-9` = 36) — was 32.
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.colors.foreground)
            .disabled(!enabled)
            // real shadcn: `aria-disabled:opacity-50`, was 0.4.
            .opacity(enabled ? 1 : 0.5)
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
