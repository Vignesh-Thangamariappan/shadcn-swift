import SwiftUI

/// shadcn-swift component: alert
/// depends on: tokens
///
/// `UI.Alert` is namespaced same as everything else, but this one's worth
/// calling out: SwiftUI already has a real (if legacy) `Alert` struct used
/// with the old `.alert(isPresented:content:)` modifier. This is an inline
/// banner, not a modal — an unrelated shape that happens to share the name
/// shadcn uses, which is exactly the case the UI namespace exists for.
public extension UI {
    enum AlertVariant {
        case `default`, destructive
    }

    struct Alert: View {
        @Environment(\.uiTheme) private var theme

        private let title: String
        private let message: String?
        private let variant: AlertVariant

        public init(_ title: String, message: String? = nil, variant: AlertVariant = .default) {
            self.title = title
            self.message = message
            self.variant = variant
        }

        public var body: some View {
            HStack(alignment: .top, spacing: theme.spacing.sm) {
                Image(systemName: variant == .destructive ? "exclamationmark.triangle.fill" : "info.circle.fill")
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(title)
                        .font(theme.typography.label)
                        .foregroundStyle(theme.colors.foreground)
                    if let message {
                        Text(message)
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.foreground.opacity(0.8))
                    }
                }
            }
            .padding(theme.spacing.md)
            .background(theme.colors.background)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                    .strokeBorder(tint.opacity(0.4), lineWidth: 1)
            )
        }

        private var tint: Color {
            variant == .destructive ? theme.colors.destructive : theme.colors.primary
        }
    }
}

#if DEBUG
private struct AlertPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            UI.Alert("Update available", message: "Version 2.1 is ready to install.")
            UI.Alert("Something went wrong", message: "Check your connection and try again.", variant: .destructive)
        }
        .padding()
    }
}

#Preview("Alert") {
    AlertPreview()
}
#endif
