import SwiftUI

/// shadcn-swift component: skeleton
/// depends on: tokens
public extension UI {
    struct Skeleton: View {
        @Environment(\.uiTheme) private var theme
        @State private var isPulsing = false

        public init() {}

        public var body: some View {
            RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous)
                .fill(theme.colors.secondary)
                .opacity(isPulsing ? 0.5 : 1)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
        }
    }
}
