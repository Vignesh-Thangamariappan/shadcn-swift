import SwiftUI

/// shadcn-swift component: dialog
/// depends on: tokens
///
/// shadcn's Dialog is a centered modal card over a scrim — visually nothing
/// like iOS's bottom sheet. The tempting naive port is a custom `.overlay`
/// with a `ZStack` scrim + centered card, but that renders inside the
/// PARENT's coordinate space (a dialog inside a NavigationStack detail view
/// can get clipped by a toolbar or safe area), doesn't dismiss on background
/// tap unless wired by hand, and does NOT trap accessibility focus —
/// VoiceOver reads straight through it to the content behind the scrim.
///
/// This uses `.fullScreenCover` instead: real modal presentation, real
/// focus trapping, at the cost of a full-screen transition rather than a
/// fade. `.presentationBackground(.clear)` (iOS 16.4+) is what keeps the
/// cover's own backing from painting opaque before our scrim draws — without
/// it you get a solid white/black flash under the dimmed background.
/// Background-tap-to-dismiss is wired explicitly on the scrim layer, since
/// fullScreenCover has no "outside" to tap on its own.
///
/// Parity pass against real shadcn's `dialog.tsx`: scrim was 40% opacity,
/// real shadcn is `bg-black/50`; content padding was one tier too small
/// (`.lg` instead of `.xl`, i.e. `p-6`); a `border` + `shadow-lg` on the
/// card and the default top-right close button were both missing entirely.
/// All fixed below.
public extension View {
    func uiDialog<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        fullScreenCover(isPresented: isPresented) {
            UI.DialogContent(isPresented: isPresented, content: content)
                .presentationBackground(.clear)
        }
    }
}

public extension UI {
    struct DialogContent<Content: View>: View {
        @Environment(\.uiTheme) private var theme
        let isPresented: Binding<Bool>
        let content: () -> Content

        public var body: some View {
            ZStack {
                // real shadcn's DialogOverlay is `bg-black/50`, not 40%.
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented.wrappedValue = false }

                content()
                    // real shadcn's DialogContent is `p-6` (24px) — was
                    // using `.lg` (16px), one tier too small.
                    .padding(theme.spacing.xl)
                    .background(theme.colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                            .strokeBorder(theme.colors.border, lineWidth: 1)
                    )
                    .uiShadow(theme.shadow.lg) // real shadcn's dialog content has `shadow-lg`
                    .overlay(alignment: .topTrailing) {
                        // real shadcn's DialogContent always renders a
                        // top-right close X (`showCloseButton` defaults to
                        // true) — `.fullScreenCover` has no native dismiss
                        // affordance of its own, unlike `.sheet`'s drag
                        // indicator, so this isn't optional here.
                        SwiftUI.Button {
                            isPresented.wrappedValue = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(theme.colors.mutedForeground)
                        }
                        .padding(theme.spacing.md)
                    }
                    .padding(theme.spacing.xl)
            }
        }
    }
}

#if DEBUG
private struct DialogPreview: View {
    @State private var isPresented = false

    var body: some View {
        Text("Host content")
            .uiDialog(isPresented: $isPresented) {
                VStack(spacing: 12) {
                    Text("Delete project?").font(.headline)
                    Text("This action can't be undone.")
                    Button("Delete", role: .destructive) {}
                }
            }
            .onAppear { isPresented = true }
    }
}

#Preview("Dialog") {
    DialogPreview()
}
#endif
