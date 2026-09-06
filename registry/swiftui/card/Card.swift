import SwiftUI

/// shadcn-swift component: card
/// depends on: tokens, button
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
                        .foregroundStyle(theme.colors.foreground)
                }

                content()

                if let actionTitle, let action {
                    UI.Button(variant: .ghost, action: action) {
                        Text(actionTitle)
                    }
                }
            }
            .padding(theme.spacing.lg)
            .background(theme.colors.background)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                    .strokeBorder(theme.colors.border, lineWidth: 1)
            )
        }
    }
}
