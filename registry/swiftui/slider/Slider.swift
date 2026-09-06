import SwiftUI

/// shadcn-swift component: slider
/// depends on: tokens
///
/// Thin themed wrapper over native `Slider` — SwiftUI's own control already
/// owns track/thumb rendering and drag handling, so there's nothing to
/// reimplement, same reasoning as select/dropdown-menu.
public extension UI {
    struct Slider: View {
        @Environment(\.uiTheme) private var theme

        @Binding private var value: Double
        private let range: ClosedRange<Double>
        private let step: Double

        public init(value: Binding<Double>, in range: ClosedRange<Double> = 0...1, step: Double = 0.01) {
            self._value = value
            self.range = range
            self.step = step
        }

        public var body: some View {
            SwiftUI.Slider(value: $value, in: range, step: step)
                .tint(theme.colors.primary)
        }
    }
}

#if DEBUG
private struct SliderPreview: View {
    @State private var value = 0.4

    var body: some View {
        UI.Slider(value: $value)
            .padding()
    }
}

#Preview("Slider") {
    SliderPreview()
}
#endif
