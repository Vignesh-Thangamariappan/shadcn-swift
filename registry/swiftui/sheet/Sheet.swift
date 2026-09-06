import SwiftUI

/// shadcn-swift component: sheet
/// depends on: tokens
///
/// Modifier-shaped, not a View struct: SwiftUI already owns the presentation
/// (native `.sheet`), so there is no portal problem to solve here — this is
/// a themed wrapper (padding, drag indicator, detents), applied to whatever
/// trigger content you already have, same as `.uiTheme(_:)`.
public extension View {
    func uiSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        sheet(isPresented: isPresented) {
            UI.SheetContent(content: content)
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium, .large])
        }
    }
}

public extension UI {
    struct SheetContent<Content: View>: View {
        @Environment(\.uiTheme) private var theme
        let content: () -> Content

        public var body: some View {
            content()
                .padding(theme.spacing.lg)
        }
    }
}

#if DEBUG
/// Presentation modifiers render nothing until their binding flips true, so
/// the preview auto-triggers on appear — the trigger content itself is just
/// a placeholder, the sheet is the thing being demonstrated.
private struct SheetPreview: View {
    @State private var isPresented = false

    var body: some View {
        Text("Host content")
            .uiSheet(isPresented: $isPresented) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sheet").font(.headline)
                    Text("Slides up from the bottom with themed padding, a drag indicator, and medium/large detents.")
                }
            }
            .onAppear { isPresented = true }
    }
}

#Preview("Sheet") {
    SheetPreview()
}
#endif
