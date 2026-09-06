import SwiftUI

/// shadcn-swift component: collapsible
/// depends on: tokens
public extension UI {
    struct Collapsible<Label: View, Content: View>: View {
        @Environment(\.uiTheme) private var theme
        @State private var isExpanded: Bool

        private let label: () -> Label
        private let content: () -> Content

        public init(
            initiallyExpanded: Bool = false,
            @ViewBuilder label: @escaping () -> Label,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self._isExpanded = State(initialValue: initiallyExpanded)
            self.label = label
            self.content = content
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                SwiftUI.Button {
                    withAnimation(.easeOut(duration: 0.2)) { isExpanded.toggle() }
                } label: {
                    HStack {
                        label()
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.colors.foreground)

                if isExpanded {
                    content()
                }
            }
        }
    }
}

#if DEBUG
private struct CollapsiblePreview: View {
    var body: some View {
        UI.Collapsible(initiallyExpanded: true) {
            Text("Advanced settings").font(.headline)
        } content: {
            Text("Hidden content revealed when expanded.")
        }
        .padding()
    }
}

#Preview("Collapsible") {
    CollapsiblePreview()
}
#endif
