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

#if DEBUG
private struct SkeletonPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            UI.Skeleton().frame(width: 160, height: 16)
            UI.Skeleton().frame(width: 220, height: 16)
            UI.Skeleton().frame(width: 120, height: 16)
        }
        .padding()
    }
}

#Preview("Skeleton") {
    SkeletonPreview()
}
#endif
