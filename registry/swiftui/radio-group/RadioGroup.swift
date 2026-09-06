import SwiftUI

/// shadcn-swift component: radio-group
/// depends on: tokens
public extension UI {
    struct RadioGroup<Option: Hashable>: View {
        @Environment(\.uiTheme) private var theme

        private let options: [Option]
        private let label: (Option) -> String
        @Binding private var selection: Option

        public init(
            options: [Option],
            selection: Binding<Option>,
            label: @escaping (Option) -> String
        ) {
            self.options = options
            self._selection = selection
            self.label = label
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                ForEach(options, id: \.self) { option in
                    SwiftUI.Button {
                        selection = option
                    } label: {
                        HStack(spacing: theme.spacing.sm) {
                            Circle()
                                .strokeBorder(
                                    option == selection ? theme.colors.primary : theme.colors.border,
                                    lineWidth: 1
                                )
                                .frame(width: 20, height: 20)
                                .overlay {
                                    if option == selection {
                                        Circle().fill(theme.colors.primary).padding(5)
                                    }
                                }
                            Text(label(option))
                                .font(theme.typography.body)
                                .foregroundStyle(theme.colors.foreground)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#if DEBUG
private struct RadioGroupPreview: View {
    @State private var plan = "pro"

    var body: some View {
        UI.RadioGroup(options: ["free", "pro", "team"], selection: $plan) { $0.capitalized }
            .padding()
    }
}

#Preview("RadioGroup") {
    RadioGroupPreview()
}
#endif
