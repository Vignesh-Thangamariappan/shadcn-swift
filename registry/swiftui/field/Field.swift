import SwiftUI

/// shadcn-swift component: field
/// depends on: tokens, label, input (the preview demonstrates wrapping
/// UI.Input, which is the realistic/common case — the type itself is
/// generic over any Control, so it also wraps UI.TextArea, UI.Select,
/// UI.Checkbox, or a bare SwiftUI control just as well)
///
/// Real shadcn's `field.tsx` exports ten pieces (`Field`, `FieldSet`,
/// `FieldLegend`, `FieldGroup`, `FieldContent`, `FieldLabel`, `FieldTitle`,
/// `FieldDescription`, `FieldSeparator`, `FieldError`) — fetched and ported
/// in full here, not just the single vertical label+control+description
/// case an earlier pass shipped. Three honest, documented approximations
/// where CSS has no SwiftUI equivalent:
/// - `FieldOrientation.responsive` uses `horizontalSizeClass` as a stand-in
///   for real shadcn's `@container` query — compact-width acts like
///   `.vertical`, regular-width like `.horizontal`. Not identical (a
///   container query responds to the immediate parent's width, not the
///   whole window's size class), but the closest native SwiftUI signal.
/// - `FieldLabel`'s bordered "choice card" look (`has-[>[data-slot=field]]:
///   border ...`, `has-data-[state=checked]:border-primary`) is CSS
///   structural-selector magic with no SwiftUI equivalent — ported as
///   explicit `isCard`/`isSelected` parameters the caller sets instead of
///   it being auto-detected from nesting a `Field` inside.
/// - `FieldSet`'s tighter `gap-3` when it directly contains a checkbox/
///   radio group, and `FieldGroup`'s tighter nested-group gap, are both
///   parent-detects-child-type CSS selectors — not ported; both always use
///   their base gap (`gap-6`/`gap-7`) regardless of what's inside.
/// Two literal pixel values below (`FieldLegend`'s 16pt "legend" variant,
/// `FieldGroup`'s 28pt gap, `FieldContent`'s 6pt gap) don't land on an
/// existing `theme.spacing`/`theme.typography` tier — hardcoded with a
/// comment at each site, same precedent as `Checkbox.swift`'s hardcoded
/// corner radius, rather than adding a token this file isn't scoped to own.
public extension UI {
    enum FieldOrientation {
        case vertical, horizontal, responsive
    }

    struct Field<Control: View>: View {
        @Environment(\.uiTheme) private var theme

        private let label: String?
        private let description: String?
        private let error: String?
        private let orientation: FieldOrientation
        private let control: () -> Control

        public init(
            _ label: String? = nil,
            description: String? = nil,
            error: String? = nil,
            orientation: FieldOrientation = .vertical,
            @ViewBuilder control: @escaping () -> Control
        ) {
            self.label = label
            self.description = description
            self.error = error
            self.orientation = orientation
            self.control = control
        }

        public var body: some View {
            layout {
                if let label {
                    UI.Label(label)
                }

                control()

                if let error {
                    UI.FieldError(error)
                } else if let description {
                    UI.FieldDescription(description)
                }
            }
        }

        #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        #endif

        @ViewBuilder
        private func layout<Content: View>(@ViewBuilder content: () -> Content) -> some View {
            switch resolvedOrientation {
            case .vertical:
                VStack(alignment: .leading, spacing: theme.spacing.md, content: content)
            case .horizontal, .responsive:
                HStack(alignment: .center, spacing: theme.spacing.md, content: content)
            }
        }

        /// `.responsive` resolves to `.vertical`/`.horizontal` via
        /// `horizontalSizeClass` — see the file header for why this is an
        /// approximation, not a literal container-query port.
        private var resolvedOrientation: FieldOrientation {
            #if os(iOS)
            if orientation == .responsive {
                return horizontalSizeClass == .compact ? .vertical : .horizontal
            }
            #endif
            return orientation == .responsive ? .horizontal : orientation
        }
    }

    /// Real shadcn's `<fieldset>` grouping — `gap-6` (`theme.spacing.xl`)
    /// between direct children.
    struct FieldSet<Content: View>: View {
        @Environment(\.uiTheme) private var theme
        private let content: () -> Content

        public init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: theme.spacing.xl, content: content)
        }
    }

    /// Real shadcn's `FieldLegend` — `variant: .legend` (the default) is
    /// `text-base font-medium` (16pt; no exact token tier, hardcoded);
    /// `.label` is `text-sm font-medium`, an exact match for
    /// `theme.typography.label`.
    struct FieldLegend: View {
        @Environment(\.uiTheme) private var theme
        public enum Style { case legend, label }

        private let title: String
        private let style: Style

        public init(_ title: String, style: Style = .legend) {
            self.title = title
            self.style = style
        }

        public var body: some View {
            Text(title)
                .font(style == .legend ? .system(size: 16, weight: .medium) : theme.typography.label)
                .foregroundStyle(theme.colors.foreground)
                .padding(.bottom, theme.spacing.md) // real shadcn: `mb-3` (12px)
        }
    }

    /// Real shadcn's vertical stack of `Field`s — `gap-7` (28px; no exact
    /// token tier, hardcoded).
    struct FieldGroup<Content: View>: View {
        private let content: () -> Content

        public init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: 28, content: content)
        }
    }

    /// Real shadcn's label+description grouping used on the content side of
    /// a horizontal `Field` — `gap-1.5` (6px; no exact token tier, hardcoded).
    struct FieldContent<Content: View>: View {
        private let content: () -> Content

        public init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: 6, content: content)
        }
    }

    /// Real shadcn's `FieldLabel` wraps a native `<Label>` and, when it
    /// structurally contains a `Field` (CSS `has-[>[data-slot=field]]`),
    /// grows into a bordered, padded "choice card" that tints on
    /// `data-state=checked`. SwiftUI has no structural-selector equivalent,
    /// so that's `isCard`/`isSelected` here instead of auto-detection — see
    /// the file header. `isCard: false` (the default) renders exactly like
    /// a plain `UI.Label`-style row, for the common non-card usage.
    struct FieldLabel<Content: View>: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.isEnabled) private var isEnabled

        private let isCard: Bool
        private let isSelected: Bool
        private let onTap: (() -> Void)?
        private let content: () -> Content

        /// `onTap`: real shadcn's card mode is a native `<label>` wrapping
        /// the control, which browsers activate on click for free. SwiftUI
        /// has no such implicit forwarding, so without this the card LOOKS
        /// tappable but only its tiny embedded checkbox/radio actually
        /// responds — a real hit-testing gap, not a cosmetic one. Pass the
        /// same toggle you'd wire to the control's own binding.
        public init(
            isCard: Bool = false,
            isSelected: Bool = false,
            onTap: (() -> Void)? = nil,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.isCard = isCard
            self.isSelected = isSelected
            self.onTap = onTap
            self.content = content
        }

        public var body: some View {
            if isCard {
                HStack(alignment: .top, spacing: theme.spacing.sm) {
                    content()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(theme.spacing.lg) // real shadcn: `p-4`
                .background(isSelected ? theme.colors.primary.opacity(0.05) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                        .strokeBorder(isSelected ? theme.colors.primary : theme.colors.border, lineWidth: 1)
                )
                .opacity(isEnabled ? 1 : 0.5)
                .contentShape(Rectangle())
                .onTapGesture { if isEnabled { onTap?() } }
            } else {
                HStack(alignment: .center, spacing: theme.spacing.sm) {
                    content()
                }
                .opacity(isEnabled ? 1 : 0.5)
            }
        }
    }

    /// Real shadcn's `FieldTitle` — the choice-card headline (`text-sm
    /// font-medium`), distinct from `FieldLabel` (the interactive wrapper)
    /// and `UI.Label` (a plain standalone form label).
    struct FieldTitle: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.isEnabled) private var isEnabled
        private let title: String

        public init(_ title: String) {
            self.title = title
        }

        public var body: some View {
            Text(title)
                .font(theme.typography.label)
                .foregroundStyle(theme.colors.foreground)
                .opacity(isEnabled ? 1 : 0.5)
        }
    }

    /// Real shadcn: `text-sm font-normal text-muted-foreground`.
    struct FieldDescription: View {
        @Environment(\.uiTheme) private var theme
        private let text: String

        public init(_ text: String) {
            self.text = text
        }

        public var body: some View {
            Text(text)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.mutedForeground)
        }
    }

    /// Real shadcn: a horizontal `Separator` with an optional centered
    /// label "chip" knocked out of it (`bg-background` behind the label,
    /// same trick real shadcn's CSS uses). The `-my-2` negative-margin
    /// layout trick real shadcn uses to visually tuck into a `FieldGroup`'s
    /// own gap isn't ported — SwiftUI's stack-gap model doesn't support
    /// negative spacing the way CSS margins do, so this renders as a plain
    /// in-flow divider instead.
    struct FieldSeparator: View {
        @Environment(\.uiTheme) private var theme
        private let label: String?

        public init(_ label: String? = nil) {
            self.label = label
        }

        public var body: some View {
            ZStack {
                UI.Separator()
                if let label {
                    Text(label)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.mutedForeground)
                        .padding(.horizontal, theme.spacing.sm)
                        .background(theme.colors.background)
                }
            }
        }
    }

    /// Real shadcn: `text-sm font-normal text-destructive`, `role="alert"`.
    /// Real shadcn also accepts an array of react-hook-form-style error
    /// objects and de-dupes/bullets them when there's more than one — the
    /// SwiftUI equivalent is a plain `[String]`, same rendering rule.
    struct FieldError: View {
        @Environment(\.uiTheme) private var theme
        private let messages: [String]

        public init(_ message: String) {
            self.messages = [message]
        }

        public init(messages: [String]) {
            self.messages = messages
        }

        public var body: some View {
            if messages.count > 1 {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    ForEach(messages, id: \.self) { message in
                        Text("•  \(message)")
                    }
                }
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.destructive)
            } else if let message = messages.first {
                Text(message)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.destructive)
            }
        }
    }
}

#if DEBUG
private struct FieldPreview: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isPro = true
    @State private var notify = true

    var body: some View {
        ScrollView {
            UI.FieldGroup {
                UI.FieldSet {
                    UI.FieldLegend("Account")

                    UI.Field("Email", description: "We'll never share your email.") {
                        UI.Input("you@example.com", text: $email)
                    }
                    UI.Field("Password", error: "Password must be at least 8 characters.") {
                        UI.Input("Password", text: $password, isSecure: true, isInvalid: true)
                    }
                }

                UI.FieldSeparator("or")

                UI.FieldSet {
                    UI.FieldLegend("Plan", style: .label)

                    UI.FieldLabel(isCard: true, isSelected: isPro, onTap: { isPro.toggle() }) {
                        UI.Checkbox(isOn: $isPro)
                        UI.FieldContent {
                            UI.FieldTitle("Pro")
                            UI.FieldDescription("For growing teams.")
                        }
                    }
                }

                UI.Field("Notifications", orientation: .responsive) {
                    UI.Switch("Enabled", isOn: $notify)
                }
            }
            .padding()
        }
    }
}

#Preview("Field") {
    FieldPreview()
}
#endif
