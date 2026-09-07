import SwiftUI

/// shadcn-swift component: field
/// depends on: tokens, label, input (the preview demonstrates wrapping
/// UI.Input, which is the realistic/common case — the type itself is
/// generic over any Control, so it also wraps UI.TextArea, UI.Select,
/// UI.Checkbox, or a bare SwiftUI control just as well)
///
/// The composition primitive the label/input/error atoms were missing:
/// label + control + description-or-error as one unit, so building a form
/// doesn't mean manually wiring UI.Label + UI.Input + an error Text at
/// every call site. Wraps ANY control — UI.Input, UI.TextArea, UI.Select,
/// UI.Checkbox, a bare Picker, whatever — since `Control` is generic.
///
/// Real shadcn's `field.tsx` is a much larger family (`FieldSet`,
/// `FieldLegend`, `FieldGroup`, horizontal/responsive orientation,
/// `FieldSeparator`, a bordered/checked-state `FieldLabel` variant for
/// radio-card-style selection UIs) — not ported here; this covers the
/// single most common case (a standalone vertical label+control+
/// description field) and is a real, larger gap than a token fix, left for
/// a dedicated follow-up. What WAS fixed here: `FieldDescription`/
/// `FieldError` are real shadcn's `text-sm font-normal` (regular weight)
/// — this file had `theme.typography.label` (medium weight) on both,
/// and the outer gap was `theme.spacing.xs` (4px) where real `Field`'s
/// own gap is `gap-3` (12px, `theme.spacing.md`).
public extension UI {
    struct Field<Control: View>: View {
        @Environment(\.uiTheme) private var theme

        private let label: String?
        private let description: String?
        private let error: String?
        private let control: () -> Control

        public init(
            _ label: String? = nil,
            description: String? = nil,
            error: String? = nil,
            @ViewBuilder control: @escaping () -> Control
        ) {
            self.label = label
            self.description = description
            self.error = error
            self.control = control
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                if let label {
                    UI.Label(label)
                }

                control()

                if let error {
                    Text(error)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.destructive)
                } else if let description {
                    Text(description)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.mutedForeground)
                }
            }
        }
    }
}

#if DEBUG
private struct FieldPreview: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            UI.Field("Email", description: "We'll never share your email.") {
                UI.Input("you@example.com", text: $email)
            }
            UI.Field("Password", error: "Password must be at least 8 characters.") {
                UI.Input("Password", text: $password, isSecure: true, isInvalid: true)
            }
        }
        .padding()
    }
}

#Preview("Field") {
    FieldPreview()
}
#endif
