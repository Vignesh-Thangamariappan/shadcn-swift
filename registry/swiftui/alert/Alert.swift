import SwiftUI

/// shadcn-swift component: alert
/// depends on: tokens
///
/// `UI.Alert` is namespaced same as everything else, but this one's worth
/// calling out: SwiftUI already has a real (if legacy) `Alert` struct used
/// with the old `.alert(isPresented:content:)` modifier. This is an inline
/// banner, not a modal — an unrelated shape that happens to share the name
/// shadcn uses, which is exactly the case the UI namespace exists for.
///
/// Uses `card`/`cardForeground` for its surface (real shadcn's Alert is
/// `bg-card text-card-foreground`) and `mutedForeground` for the secondary
/// message line, matching shadcn's `text-muted-foreground` on that element.
///
/// Corner radius is `theme.radius.lg` — real shadcn's Alert is `rounded-lg`.
/// An earlier version used `md`, one tier too tight.
///
/// The border is always plain `theme.colors.border`, in BOTH variants — real
/// shadcn's `alertVariants` cva only tints TEXT (`text-destructive` on the
/// container, `text-destructive/90` on the description) for the destructive
/// variant; its base `border` class carries no variant override at all. An
/// earlier version tinted the border to `primary`/`destructive`, which real
/// shadcn never does. Same fix applies to the icon and title: shadcn's icon
/// is `[&>svg]:text-current` (inherits the container's text color) and the
/// title sets no color of its own — so both simply follow the container's
/// text color (`cardForeground` default / `destructive` when destructive),
/// they don't independently reach for `primary` the way an earlier version
/// did for the default variant.
public extension UI {
    enum AlertVariant {
        case `default`, destructive
    }

    struct Alert: View {
        @Environment(\.uiTheme) private var theme

        private let title: String
        private let message: String?
        private let variant: AlertVariant
        private let shape: UI.Theme.CornerStyle?

        public init(
            _ title: String,
            message: String? = nil,
            variant: AlertVariant = .default,
            shape: UI.Theme.CornerStyle? = nil
        ) {
            self.title = title
            self.message = message
            self.variant = variant
            self.shape = shape
        }

        // `shape: .full` mirrors real shadcn's `className="rounded-full"`
        // override — see `Button.swift`'s header for why this needs to be a
        // real parameter rather than a second `.clipShape` from outside.
        private var cornerRadius: CGFloat {
            (shape ?? .radius(theme.radius.lg)).cornerRadius
        }

        public var body: some View {
            HStack(alignment: .top, spacing: theme.spacing.sm) {
                Image(systemName: variant == .destructive ? "exclamationmark.triangle.fill" : "info.circle.fill")
                    .foregroundStyle(contentColor)

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(title)
                        .font(theme.typography.label)
                        .foregroundStyle(contentColor)
                    if let message {
                        Text(message)
                            .font(theme.typography.body)
                            .foregroundStyle(variant == .destructive ? theme.colors.destructive.opacity(0.9) : theme.colors.mutedForeground)
                    }
                }
            }
            .padding(theme.spacing.md)
            .background(theme.colors.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(theme.colors.border, lineWidth: 1)
            )
        }

        private var contentColor: Color {
            variant == .destructive ? theme.colors.destructive : theme.colors.cardForeground
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
