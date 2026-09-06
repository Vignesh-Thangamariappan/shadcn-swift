import SwiftUI

/// shadcn-swift component: spinner
/// depends on: tokens
///
/// A hand-drawn rotating arc rather than `ProgressView(.circular)` — same
/// reasoning as UI.Switch avoiding `.tint()`: a native spinner's color is
/// OS-version-dependent about which tint API it actually honors, and this
/// guarantees theme colors apply the same way every other component here does.
public extension UI {
    struct Spinner: View {
        @Environment(\.uiTheme) private var theme
        @State private var isRotating = false

        private let size: CGFloat

        public init(size: CGFloat = 20) {
            self.size = size
        }

        public var body: some View {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(theme.colors.primary, style: StrokeStyle(lineWidth: max(size / 8, 2), lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .onAppear {
                    withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                        isRotating = true
                    }
                }
        }
    }
}

#if DEBUG
private struct SpinnerPreview: View {
    var body: some View {
        HStack(spacing: 16) {
            UI.Spinner(size: 16)
            UI.Spinner(size: 24)
            UI.Spinner(size: 32)
        }
        .padding()
    }
}

#Preview("Spinner") {
    SpinnerPreview()
}
#endif
