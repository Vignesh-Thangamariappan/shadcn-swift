import SwiftUI

/// shadcn-swift component: skeleton
/// depends on: tokens
///
/// Fill is `theme.colors.accent` — real shadcn's Skeleton is literally
/// `bg-accent` (verified against the actual `skeleton.tsx` — the previous
/// doc comment here claimed `bg-muted`, which was never actually checked
/// against the real source and was wrong).
///
/// Corner radius is `theme.radius.md` — real shadcn's Skeleton is
/// `rounded-md`. An earlier version used `sm`, one tier too tight.
///
/// Pulse timing matches Tailwind's actual `animate-pulse` keyframe: `pulse
/// 2s cubic-bezier(0.4, 0, 0.6, 1) infinite` (opacity 1↔0.5) — an earlier
/// version ran at 0.9s with `.easeInOut`, noticeably faster and on a
/// different curve than real shadcn's.
public extension UI {
    struct Skeleton: View {
        @Environment(\.uiTheme) private var theme
        @State private var isPulsing = false

        public init() {}

        public var body: some View {
            RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                .fill(theme.colors.accent)
                .opacity(isPulsing ? 0.5 : 1)
                .onAppear {
                    withAnimation(.timingCurve(0.4, 0, 0.6, 1, duration: 2).repeatForever(autoreverses: true)) {
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
