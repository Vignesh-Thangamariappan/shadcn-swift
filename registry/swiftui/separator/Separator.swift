import SwiftUI

/// shadcn-swift component: separator
/// depends on: tokens
public extension UI {
    struct Separator: View {
        @Environment(\.uiTheme) private var theme
        private let orientation: Axis

        public init(_ orientation: Axis = .horizontal) {
            self.orientation = orientation
        }

        public var body: some View {
            Rectangle()
                .fill(theme.colors.border)
                .frame(
                    width: orientation == .vertical ? 1 : nil,
                    height: orientation == .horizontal ? 1 : nil
                )
        }
    }
}
