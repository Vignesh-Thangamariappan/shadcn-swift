import SwiftUI

/// shadcn-swift component: empty
/// depends on: tokens, button
public extension UI {
    struct Empty: View {
        @Environment(\.uiTheme) private var theme

        private let systemImage: String
        private let title: String
        private let description: String?
        private let actionTitle: String?
        private let action: (() -> Void)?

        public init(
            systemImage: String,
            title: String,
            description: String? = nil,
            actionTitle: String? = nil,
            action: (() -> Void)? = nil
        ) {
            self.systemImage = systemImage
            self.title = title
            self.description = description
            self.actionTitle = actionTitle
            self.action = action
        }

        public var body: some View {
            VStack(spacing: theme.spacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 32))
                    .foregroundStyle(theme.colors.mutedForeground)

                Text(title)
                    .font(theme.typography.label)
                    .foregroundStyle(theme.colors.foreground)

                if let description {
                    Text(description)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.mutedForeground)
                        .multilineTextAlignment(.center)
                }

                if let actionTitle, let action {
                    UI.Button(variant: .outline, action: action) {
                        Text(actionTitle)
                    }
                    .padding(.top, theme.spacing.sm)
                }
            }
            .padding(theme.spacing.xl)
            .frame(maxWidth: .infinity)
        }
    }
}

#if DEBUG
private struct EmptyPreview: View {
    var body: some View {
        UI.Empty(
            systemImage: "tray",
            title: "No messages",
            description: "New messages will show up here.",
            actionTitle: "Refresh",
            action: {}
        )
    }
}

#Preview("Empty") {
    EmptyPreview()
}
#endif
