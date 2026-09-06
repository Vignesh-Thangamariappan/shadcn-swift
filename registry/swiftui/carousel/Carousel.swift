import SwiftUI

/// shadcn-swift component: carousel
/// depends on: tokens
///
/// Built on native `TabView(.page)` rather than a hand-rolled paging
/// ScrollView — SwiftUI's own paging already handles swipe gestures,
/// velocity-based settling, and accessibility paging actions correctly.
///
/// Scope limitation, not an oversight: `TabView(.page)` needs a concrete
/// height (it doesn't measure per-page content and adapt), so `height`
/// is a required-ish parameter (defaults to 200) rather than something
/// that hugs arbitrary content — pass your own if pages aren't ~200pt tall.
public extension UI {
    struct Carousel<Content: View>: View {
        @Environment(\.uiTheme) private var theme
        @Binding private var selection: Int

        private let itemCount: Int
        private let height: CGFloat
        private let content: (Int) -> Content

        public init(
            selection: Binding<Int>,
            itemCount: Int,
            height: CGFloat = 200,
            @ViewBuilder content: @escaping (Int) -> Content
        ) {
            self._selection = selection
            self.itemCount = itemCount
            self.height = height
            self.content = content
        }

        public var body: some View {
            VStack(spacing: theme.spacing.sm) {
                TabView(selection: $selection) {
                    ForEach(0..<itemCount, id: \.self) { index in
                        content(index).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: height)

                HStack(spacing: 6) {
                    ForEach(0..<itemCount, id: \.self) { index in
                        Circle()
                            .fill(index == selection ? theme.colors.primary : theme.colors.muted)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
    }
}

#if DEBUG
private struct CarouselPreview: View {
    @State private var page = 0

    var body: some View {
        UI.Carousel(selection: $page, itemCount: 3) { index in
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .overlay(Text("Slide \(index + 1)"))
        }
        .padding()
    }
}

#Preview("Carousel") {
    CarouselPreview()
}
#endif
