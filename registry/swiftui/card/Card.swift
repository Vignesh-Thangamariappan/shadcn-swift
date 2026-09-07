import SwiftUI

/// shadcn-swift component: card
/// depends on: tokens, button
///
/// Uses `theme.colors.card`/`cardForeground`, not `background`/`foreground` —
/// a real shadcn Card is its own surface token, even though it defaults to
/// the same value as the page background.
///
/// Corner radius is `theme.radius.xl` — real shadcn's Card is `rounded-xl`,
/// the one component that isn't `rounded-lg`/`rounded-md`. An earlier
/// version used `lg` here, which was also the wrong number for `lg` itself
/// (12 instead of 10) — both fixed in a parity pass against real shadcn's
/// computed `--radius-*` scale. `shape: .full` overrides this the same way
/// real shadcn's `className="rounded-full"` would (see `Button.swift`'s
/// header for why this has to be a real parameter, not a second
/// `.clipShape` layered on from outside).
public extension UI {
    struct Card<Content: View>: View {
        @Environment(\.uiTheme) private var theme

        private let title: String?
        private let actionTitle: String?
        private let action: (() -> Void)?
        private let shape: UI.Theme.CornerStyle?
        private let content: () -> Content

        public init(
            title: String? = nil,
            actionTitle: String? = nil,
            action: (() -> Void)? = nil,
            shape: UI.Theme.CornerStyle? = nil,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.title = title
            self.actionTitle = actionTitle
            self.action = action
            self.shape = shape
            self.content = content
        }

        private var cornerRadius: CGFloat {
            (shape ?? .radius(theme.radius.xl)).cornerRadius
        }

        public var body: some View {
            // Real shadcn's Card is `flex flex-col gap-6 ... py-6 shadow-sm`,
            // with each of CardHeader/CardContent/CardFooter separately
            // adding `px-6` — net result is 24pt padding on every side and
            // a 24pt gap between sections, not the 16pt/8pt this used
            // before parity was checked against the live `card.tsx` source.
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                if let title {
                    Text(title)
                        // CardTitle has no text-size class in real shadcn
                        // (just `font-semibold`) — it inherits the 16px
                        // base size, not `text-lg`(18) like DialogTitle.
                        // Hardcoded rather than reusing `theme.typography.title`
                        // (18/semibold, correct for Dialog) to avoid
                        // conflating two real shadcn values that differ.
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.colors.cardForeground)
                }

                content()

                if let actionTitle, let action {
                    UI.Button(variant: .ghost, action: action) {
                        Text(actionTitle)
                    }
                }
            }
            .padding(theme.spacing.xl)
            .background(theme.colors.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(theme.colors.border, lineWidth: 1)
            )
            .uiShadow(theme.shadow.sm)
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
            UI.Card(shape: .full) {
                Text("Rounded full")
            }
        }
        .padding()
    }
}

#Preview("Card") {
    CardPreview()
}
#endif
