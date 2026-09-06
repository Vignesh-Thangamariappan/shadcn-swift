import SwiftUI

/// shadcn-swift component: kbd
/// depends on: tokens
public extension UI {
    struct Kbd: View {
        @Environment(\.uiTheme) private var theme

        private let text: String

        public init(_ text: String) {
            self.text = text
        }

        public var body: some View {
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(theme.colors.muted)
                .foregroundStyle(theme.colors.mutedForeground)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous))
        }
    }
}

#if DEBUG
private struct KbdPreview: View {
    var body: some View {
        HStack(spacing: 6) {
            UI.Kbd("⌘")
            UI.Kbd("K")
        }
        .padding()
    }
}

#Preview("Kbd") {
    KbdPreview()
}
#endif
