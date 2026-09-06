import SwiftUI

/// shadcn-swift component: toggle-group
/// depends on: tokens, toggle
///
/// A row of UI.Toggle, matching shadcn's ToggleGroup which is exactly that:
/// several Toggle primitives sharing selection state. Single-selection
/// (Binding<Option>) and multiple-selection (Binding<Set<Option>>) both
/// funnel through the same Set-backed body — the single-selection
/// initializer just adapts a scalar binding into a one-element Set.
public extension UI {
    struct ToggleGroup<Option: Hashable>: View {
        private let options: [Option]
        private let icon: (Option) -> String
        @Binding private var selection: Set<Option>

        public init(options: [Option], selection: Binding<Set<Option>>, icon: @escaping (Option) -> String) {
            self.options = options
            self.icon = icon
            self._selection = selection
        }

        public init(options: [Option], selection: Binding<Option>, icon: @escaping (Option) -> String) {
            self.options = options
            self.icon = icon
            self._selection = Binding(
                get: { [selection.wrappedValue] },
                set: { newValue in
                    if let first = newValue.first { selection.wrappedValue = first }
                }
            )
        }

        public var body: some View {
            HStack(spacing: 4) {
                ForEach(options, id: \.self) { option in
                    UI.Toggle(
                        systemImage: icon(option),
                        isOn: Binding(
                            get: { selection.contains(option) },
                            set: { isOn in
                                if isOn { selection.insert(option) } else { selection.remove(option) }
                            }
                        )
                    )
                }
            }
        }
    }
}

#if DEBUG
private struct ToggleGroupPreview: View {
    @State private var alignment = "left"
    @State private var styles: Set<String> = ["bold"]

    var body: some View {
        VStack(spacing: 16) {
            UI.ToggleGroup(
                options: ["left", "center", "right"],
                selection: $alignment,
                icon: { ["left": "text.alignleft", "center": "text.aligncenter", "right": "text.alignright"][$0]! }
            )
            UI.ToggleGroup(
                options: ["bold", "italic", "underline"],
                selection: $styles,
                icon: { $0 }
            )
        }
        .padding()
    }
}

#Preview("ToggleGroup") {
    ToggleGroupPreview()
}
#endif
