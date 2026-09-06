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

#if DEBUG
private struct SeparatorPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Above")
            UI.Separator()
            Text("Below")

            HStack(spacing: 12) {
                Text("Left")
                UI.Separator(.vertical)
                Text("Right")
            }
            .frame(height: 24)
        }
        .padding()
    }
}

#Preview("Separator") {
    SeparatorPreview()
}
#endif
