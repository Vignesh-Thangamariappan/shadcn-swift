import SwiftUI

/// shadcn-swift component: kbd
/// depends on: tokens
///
/// Real shadcn's `kbd.tsx` is explicitly `font-sans` — despite the "keyboard
/// key" convention elsewhere on the web, this is NOT monospaced (verified
/// against the live source, not assumed). Also a fixed `h-5 w-fit min-w-5`
/// (20pt, content-sized but never smaller), not padding-derived height.
public extension UI {
    struct Kbd: View {
        @Environment(\.uiTheme) private var theme

        private let text: String

        public init(_ text: String) {
            self.text = text
        }

        public var body: some View {
            Text(text)
                .font(theme.typography.caption)
                .padding(.horizontal, theme.spacing.xs)
                .frame(minWidth: 20, minHeight: 20)
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
