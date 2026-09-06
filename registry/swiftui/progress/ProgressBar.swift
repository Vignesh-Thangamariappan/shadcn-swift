import SwiftUI

/// shadcn-swift component: progress
/// depends on: tokens
///
/// Named ProgressBar, not Progress: SwiftUI already has ProgressView and
/// Foundation has NSProgress imported as Progress — the UI namespace would
/// keep either from clashing, but a name that isn't a near-duplicate of an
/// existing SwiftUI/Foundation type is one less thing to double-take on.
public extension UI {
    struct ProgressBar: View {
        @Environment(\.uiTheme) private var theme
        private let value: Double

        public init(value: Double) {
            self.value = min(max(value, 0), 1)
        }

        public var body: some View {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.colors.secondary)
                    Capsule()
                        .fill(theme.colors.primary)
                        .frame(width: proxy.size.width * value)
                }
            }
            .frame(height: 8)
            .animation(.easeOut(duration: 0.2), value: value)
        }
    }
}

#if DEBUG
private struct ProgressBarPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            UI.ProgressBar(value: 0)
            UI.ProgressBar(value: 0.3)
            UI.ProgressBar(value: 0.7)
            UI.ProgressBar(value: 1)
        }
        .padding()
    }
}

#Preview("ProgressBar") {
    ProgressBarPreview()
}
#endif
