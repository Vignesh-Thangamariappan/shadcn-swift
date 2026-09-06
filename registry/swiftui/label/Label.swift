import SwiftUI

/// shadcn-swift component: label
/// depends on: tokens
public extension UI {
    struct Label: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.isEnabled) private var isEnabled

        private let text: String

        public init(_ text: String) {
            self.text = text
        }

        public var body: some View {
            Text(text)
                .font(theme.typography.label)
                .foregroundStyle(theme.colors.foreground)
                .opacity(isEnabled ? 1 : 0.5)
        }
    }
}
