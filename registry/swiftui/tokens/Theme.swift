import SwiftUI

/// shadcn-swift component: tokens
/// Namespaced under `UI` so it never shadows a SwiftUI type.
public enum UI {
    public struct Theme {
        public var colors: Colors
        public var spacing: Spacing
        public var radius: Radius
        public var typography: Typography
        public var shadow: Shadow

        public init(colors: Colors, spacing: Spacing, radius: Radius, typography: Typography, shadow: Shadow = .default) {
            self.colors = colors
            self.spacing = spacing
            self.radius = radius
            self.typography = typography
            self.shadow = shadow
        }

        public static let `default` = Theme(
            colors: .default,
            spacing: .default,
            radius: .default,
            typography: .default,
            shadow: .default
        )
    }
}

private struct UIThemeKey: EnvironmentKey {
    static let defaultValue: UI.Theme = .default
}

public extension EnvironmentValues {
    var uiTheme: UI.Theme {
        get { self[UIThemeKey.self] }
        set { self[UIThemeKey.self] = newValue }
    }
}

public extension View {
    /// Overrides the theme for this view and its descendants.
    /// Equivalent to swapping the CSS variable block shadcn/ui reads at :root.
    func uiTheme(_ theme: UI.Theme) -> some View {
        environment(\.uiTheme, theme)
    }
}
