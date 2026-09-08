import SwiftUI

/// shadcn-swift component: button-group
/// depends on: tokens, button
///
/// Real shadcn's `button-group.tsx` is a generic `<div>` wrapper that visually
/// joins ANY children via sibling CSS selectors (`[&>*:not(:first-child)]:
/// rounded-l-none`, etc.) — it doesn't know or care what's inside it. SwiftUI
/// has no equivalent to "reach into arbitrary `@ViewBuilder` children and
/// restyle them by position" without reaching for `_VariadicView` (an
/// underscore-prefixed, technically-private API this registry avoids in
/// vendored source). So this takes an explicit `[ButtonGroupItem]` array and
/// builds its own `UI.Button`s internally instead — the same shape
/// `UI.ToggleGroup` already uses for the identical problem. Scope limit,
/// documented rather than silent: real shadcn's `ButtonGroupText` (a static
/// label styled to sit inline with the group) and `ButtonGroupSeparator` (a
/// manual divider splitting the group into sub-clusters) aren't built here —
/// both need mixed, arbitrary content, which is exactly the generality this
/// array-based approach deliberately doesn't attempt. Add them if a real
/// screen needs that composition, not speculatively.
///
/// Corner rounding and border-collapsing both reuse `UI.Button`'s own
/// internal `buttonGroupPosition(_:orientation:)` (see `button/Button.swift`)
/// and `UI.Theme.PartialBorderShape` (`tokens/Tokens.swift`) — the exact technique
/// already verified for `UI.ToggleGroup`, generalized to support real
/// shadcn's `vertical` orientation too (`button-group.tsx`'s `orientation`
/// variant, fetched live — `ToggleGroup` never needed this, only
/// `horizontal` came up there).
public extension UI {
    struct ButtonGroupItem: Identifiable {
        public let id = UUID()
        public let title: String
        public let icon: Image?
        public let variant: ButtonVariant
        public let action: () -> Void

        public init(
            _ title: String,
            icon: Image? = nil,
            variant: ButtonVariant = .outline,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.icon = icon
            self.variant = variant
            self.action = action
        }
    }

    struct ButtonGroup: View {
        private let items: [ButtonGroupItem]
        private let orientation: UI.Theme.SegmentOrientation

        public init(_ items: [ButtonGroupItem], orientation: UI.Theme.SegmentOrientation = .horizontal) {
            self.items = items
            self.orientation = orientation
        }

        public var body: some View {
            Group {
                switch orientation {
                case .horizontal:
                    HStack(spacing: 0) { content }
                case .vertical:
                    VStack(spacing: 0) { content }
                }
            }
            // Real shadcn's group container is `w-fit` — sized to its
            // content, not stretched, matching the same `Button`-is-
            // content-sized default this registry already holds itself to.
            .fixedSize(horizontal: orientation == .horizontal, vertical: orientation == .vertical)
        }

        @ViewBuilder
        private var content: some View {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                buttonView(for: item, position: position(at: index))
            }
        }

        @ViewBuilder
        private func buttonView(for item: ButtonGroupItem, position: UI.Theme.SegmentPosition) -> some View {
            // `UI.Button`'s convenience inits take `LocalizedStringKey`
            // (for localization), not a plain runtime `String` — an
            // explicit `LocalizedStringKey(_:)` wrap is required here since
            // `item.title` is a stored `String` value, not a string literal.
            if let icon = item.icon {
                UI.Button(LocalizedStringKey(item.title), icon: icon, variant: item.variant, action: item.action)
                    .buttonGroupPosition(position, orientation: orientation)
            } else {
                UI.Button(LocalizedStringKey(item.title), variant: item.variant, action: item.action)
                    .buttonGroupPosition(position, orientation: orientation)
            }
        }

        private func position(at index: Int) -> UI.Theme.SegmentPosition {
            guard items.count > 1 else { return .standalone }
            switch index {
            case 0: return .leading
            case items.count - 1: return .trailing
            default: return .middle
            }
        }
    }
}

#if DEBUG
private struct ButtonGroupPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            UI.ButtonGroup([
                .init("Day", action: {}),
                .init("Week", action: {}),
                .init("Month", action: {})
            ])

            UI.ButtonGroup([
                .init("Copy", icon: Image(systemName: "doc.on.doc"), action: {}),
                .init("Share", icon: Image(systemName: "square.and.arrow.up"), action: {}),
                .init("Delete", icon: Image(systemName: "trash"), variant: .destructive, action: {})
            ])

            UI.ButtonGroup([
                .init("One", action: {}),
                .init("Two", action: {})
            ], orientation: .vertical)
        }
        .padding()
    }
}

#Preview("ButtonGroup") {
    ButtonGroupPreview()
}
#endif
