import SwiftUI

/// shadcn-swift component: badge
/// depends on: tokens
///
/// Variant names match real shadcn's stock `badge.tsx` `cva()` block exactly
/// (verified against a live shadcn install): `default | secondary |
/// destructive | outline | ghost | link`. An earlier version invented
/// `primary` in place of `default` and had no `destructive` variant —
/// fixed; `ghost`/`link` were missing entirely — added. Real shadcn styles
/// both only via `hover:` classes (no resting-state background/border of
/// their own) — skipped here on purpose, not an oversight: a `Badge` is a
/// static label, not an interactive element, so there's no iOS press/hover
/// state for it to key off. `link` still gets `.underline()` since that's
/// its always-on, non-hover styling, matching how `UI.Button`'s own `link`
/// variant already applies `.underline(variant == .link)`.
public extension UI {
    enum BadgeVariant {
        case `default`, secondary, destructive, outline, ghost, link
    }

    struct Badge: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.colorScheme) private var colorScheme

        private let text: String
        private let variant: BadgeVariant

        public init(_ text: String, variant: BadgeVariant = .default) {
            self.text = text
            self.variant = variant
        }

        public var body: some View {
            Text(text)
                // real shadcn: `text-xs font-medium` (12/medium) — `caption`,
                // not `label` (14/medium), which was the wrong tier.
                .font(theme.typography.caption)
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.xs / 2)
                .background(background)
                .foregroundStyle(foreground)
                .underline(variant == .link)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(border, lineWidth: variant == .outline ? 1 : 0)
                )
        }

        private var background: Color {
            switch variant {
            case .default: theme.colors.primary
            case .secondary: theme.colors.secondary
            // real shadcn: `dark:bg-destructive/60`, same dark-mode
            // adjustment already applied to UI.Button's destructive variant.
            case .destructive: colorScheme == .dark ? theme.colors.destructive.opacity(0.6) : theme.colors.destructive
            case .outline, .ghost, .link: .clear
            }
        }

        private var foreground: Color {
            switch variant {
            case .default: theme.colors.primaryForeground
            case .secondary: theme.colors.secondaryForeground
            case .destructive: .white
            case .outline, .ghost: theme.colors.foreground
            case .link: theme.colors.primary
            }
        }

        private var border: Color {
            variant == .outline ? theme.colors.border : .clear
        }
    }
}

#if DEBUG
private struct BadgePreview: View {
    var body: some View {
        HStack(spacing: 8) {
            UI.Badge("Default")
            UI.Badge("Secondary", variant: .secondary)
            UI.Badge("Destructive", variant: .destructive)
            UI.Badge("Outline", variant: .outline)
            UI.Badge("Ghost", variant: .ghost)
            UI.Badge("Link", variant: .link)
        }
        .padding()
    }
}

#Preview("Badge") {
    BadgePreview()
}
#endif
