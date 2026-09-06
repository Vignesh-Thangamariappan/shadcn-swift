import SwiftUI

/// shadcn-swift component: card
/// depends on: tokens, button
///
/// Uses `theme.colors.card`/`cardForeground`, not `background`/`foreground` —
/// a real shadcn Card is its own surface token, even though it defaults to
/// the same value as the page background.
public extension UI {
    struct Card<Content: View>: View {
        @Environment(\.uiTheme) private var theme

        private let title: String?
        private let actionTitle: String?
        private let action: (() -> Void)?
        private let content: () -> Content

        public init(
            title: String? = nil,
            actionTitle: String? = nil,
            action: (() -> Void)? = nil,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.title = title
            self.actionTitle = actionTitle
            self.action = action
            self.content = content
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                if let title {
                    Text(title)
                        .font(theme.typography.title)
                        .foregroundStyle(theme.colors.cardForeground)
                }

                content()

                if let actionTitle, let action {
                    UI.Button(variant: .ghost, action: action) {
                        Text(actionTitle)
                    }
                }
            }
            .padding(theme.spacing.lg)
            .background(theme.colors.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                    .strokeBorder(theme.colors.border, lineWidth: 1)
            )
        }
    }
}

#if DEBUG
private struct CardPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            UI.Card(title: "Storage", actionTitle: "Manage", action: {}) {
                Text("42 GB of 100 GB used")
            }
            UI.Card {
                Text("A card with no title or action — just content.")
            }
        }
        .padding()
    }
}

#Preview("Card") {
    CardPreview()
}
#endif
