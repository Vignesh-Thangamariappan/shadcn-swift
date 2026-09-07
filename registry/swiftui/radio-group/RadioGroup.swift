import SwiftUI

/// shadcn-swift component: radio-group
/// depends on: tokens
public extension UI {
    struct RadioGroup<Option: Hashable>: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.colorScheme) private var colorScheme

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
                            // Real shadcn's outer circle is `size-4` (16pt)
                            // and its border/fill do NOT change when
                            // selected — only the inner dot appears. This
                            // previously grew to 20pt and swapped the
                            // border to `primary` on selection, neither of
                            // which real shadcn does.
                            Circle()
                                .fill(circleBackground)
                                .overlay(Circle().strokeBorder(theme.colors.input, lineWidth: 1))
                                .frame(width: 16, height: 16)
                                .overlay {
                                    if option == selection {
                                        // Real shadcn's dot is `size-2` (8pt).
                                        Circle().fill(theme.colors.primary).frame(width: 8, height: 8)
                                    }
                                }
                                .uiShadow(theme.shadow.xs)
                            Text(label(option))
                                .font(theme.typography.body)
                                .foregroundStyle(theme.colors.foreground)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .opacity(isEnabled ? 1 : 0.5)
        }

        private var circleBackground: Color {
            colorScheme == .dark ? theme.colors.input.opacity(0.3) : .clear
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
