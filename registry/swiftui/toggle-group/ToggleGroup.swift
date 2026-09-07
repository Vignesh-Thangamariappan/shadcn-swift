import SwiftUI

/// shadcn-swift component: toggle-group
/// depends on: tokens, toggle
///
/// A row of UI.Toggle, matching shadcn's ToggleGroup which is exactly that:
/// several Toggle primitives sharing selection state. Single-selection
/// (Binding<Option>) and multiple-selection (Binding<Set<Option>>) both
/// funnel through the same Set-backed body — the single-selection
/// initializer just adapts a scalar binding into a one-element Set.
///
/// Real shadcn's DEFAULT mode (`spacing={0}`) renders a joined segmented
/// control: zero gap, only the first/last items keep rounded corners, the
/// rest go `rounded-none` (verified live against `toggle-group.tsx`) — now
/// implemented via `UI.Toggle`'s `groupPosition` parameter (see
/// `registry/swiftui/toggle/Toggle.swift`), which owns the actual corner
/// masking since it's the one drawing each item's `clipShape`. This file
/// only computes each item's position (first/middle/last) and passes it
/// down. A lone single-item group renders `.standalone` (all corners
/// rounded) rather than `.leading`+`.trailing` fighting each other.
///
/// `variant` mirrors real shadcn's shared `ToggleGroupContext` — when
/// `.outline`, the whole joined row gets one shared `shadow-xs` on the
/// container (matching `toggleVariants`'s own per-item shadow being
/// suppressed in joined mode: `data-[spacing=0]:shadow-none`, real
/// shadcn moves that shadow up to the group container instead).
///
/// Not reproduced: real shadcn's `spacing` prop lets a consumer opt OUT of
/// the joined look entirely (a gapped row of independent, fully-rounded
/// items). This repo's `ToggleGroup` only renders the corrected default
/// (joined) — the flagged gap was specifically that the default rendered
/// wrong, not a request for the alternate mode too.
public extension UI {
    struct ToggleGroup<Option: Hashable>: View {
        @Environment(\.uiTheme) private var theme
        private let options: [Option]
        private let icon: (Option) -> String
        private let variant: UI.ToggleVariant
        @Binding private var selection: Set<Option>

        public init(
            options: [Option],
            selection: Binding<Set<Option>>,
            variant: UI.ToggleVariant = .default,
            icon: @escaping (Option) -> String
        ) {
            self.options = options
            self.icon = icon
            self.variant = variant
            self._selection = selection
        }

        public init(
            options: [Option],
            selection: Binding<Option>,
            variant: UI.ToggleVariant = .default,
            icon: @escaping (Option) -> String
        ) {
            self.options = options
            self.icon = icon
            self.variant = variant
            self._selection = Binding(
                get: { [selection.wrappedValue] },
                set: { newValue in
                    if let first = newValue.first { selection.wrappedValue = first }
                }
            )
        }

        public var body: some View {
            HStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.element) { index, option in
                    UI.Toggle(
                        systemImage: icon(option),
                        isOn: Binding(
                            get: { selection.contains(option) },
                            set: { isOn in
                                if isOn { selection.insert(option) } else { selection.remove(option) }
                            }
                        ),
                        variant: variant,
                        groupPosition: position(at: index)
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
            .uiShadow(variant == .outline ? theme.shadow.xs : UI.Theme.Shadow.Level(color: .clear, radius: 0, y: 0))
        }

        private func position(at index: Int) -> UI.ToggleGroupPosition {
            guard options.count > 1 else { return .standalone }
            switch index {
            case 0: return .leading
            case options.count - 1: return .trailing
            default: return .middle
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
