import SwiftUI

/// shadcn-swift component: tooltip
/// depends on: tokens
///
/// shadcn's Tooltip triggers on cursor hover, which iOS has no equivalent
/// of on a touch device. This triggers on long-press instead — the closest
/// touch-native analog — and reveals the text in a themed popover.
///
/// Deviation: the shown/hidden state is a PRIVATE `@State` inside
/// `TooltipModifier`, not exposed to the caller (unlike uiSheet/uiDialog/
/// uiPopover, which all take an external `isPresented` binding). A tooltip
/// is meant to be driven purely by the gesture on its own trigger view, not
/// programmatically opened from elsewhere — same reasoning as UI.Input's
/// local FocusState. One consequence: this file's own #Preview can only
/// show the trigger at rest, not the revealed tooltip — there's no external
/// binding to flip on `.onAppear` the way uiSheet/uiDialog/uiPopover do.
/// Long-press it on a real device or simulator to see the popover.
public extension View {
    func uiTooltip(_ text: String) -> some View {
        modifier(UI.TooltipModifier(text: text))
    }
}

public extension UI {
    struct TooltipModifier: ViewModifier {
        @Environment(\.uiTheme) private var theme
        @State private var isPresented = false

        let text: String

        public func body(content: Content) -> some View {
            content
                .onLongPressGesture(minimumDuration: 0.4) {
                    isPresented = true
                }
                .popover(isPresented: $isPresented) {
                    Text(text)
                        .font(theme.typography.label)
                        .padding(theme.spacing.sm)
                        .presentationCompactAdaptation(.popover)
                }
        }
    }
}

#if DEBUG
private struct TooltipPreview: View {
    var body: some View {
        Image(systemName: "info.circle")
            .font(.title)
            .uiTooltip("Long-press to reveal this tooltip")
            .padding()
    }
}

#Preview("Tooltip") {
    TooltipPreview()
}
#endif
