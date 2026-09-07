import SwiftUI

/// shadcn-swift component: popover
/// depends on: tokens
///
/// `.presentationCompactAdaptation(.popover)` (iOS 16.4+) is load-bearing,
/// not decoration: without it, `.popover` silently becomes a full sheet on
/// iPhone's compact width, making this component behave identically to
/// `UI.uiSheet` at runtime — a correctness bug that a typecheck can't catch
/// (both compile fine either way) and only shows up on a real device/
/// simulator, never in a canvas preview run on an iPad-sized surface.
public extension View {
    func uiPopover<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        popover(isPresented: isPresented) {
            UI.PopoverContent(content: content)
                .presentationCompactAdaptation(.popover)
        }
    }
}

public extension UI {
    struct PopoverContent<Content: View>: View {
        @Environment(\.uiTheme) private var theme
        let content: () -> Content

        public var body: some View {
            content()
                // real shadcn: `rounded-md border bg-popover p-4 text-popover-foreground
                // shadow-md` — this was missing its border, radius, and shadow entirely,
                // and used `spacing.md` (12) where real `p-4` is 16 (`spacing.lg`).
                .padding(theme.spacing.lg)
                .foregroundStyle(theme.colors.popoverForeground)
                .background(theme.colors.popover)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                        .strokeBorder(theme.colors.border, lineWidth: 1)
                )
                .uiShadow(theme.shadow.md) // real shadcn's popover content has `shadow-md`
        }
    }
}

#if DEBUG
private struct PopoverPreview: View {
    @State private var isPresented = false

    var body: some View {
        Text("Host content")
            .uiPopover(isPresented: $isPresented) {
                Text("Popover content")
                    .frame(width: 200)
            }
            .onAppear { isPresented = true }
    }
}

#Preview("Popover") {
    PopoverPreview()
}
#endif
