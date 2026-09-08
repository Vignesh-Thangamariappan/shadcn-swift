import SwiftUI

/// shadcn-swift component: toast
/// depends on: tokens, spinner
///
/// Real shadcn's `sonner.tsx` is a thin theming wrapper around the external
/// `sonner` npm library — the library owns the actual queue, positioning,
/// auto-dismiss, and swipe-to-dismiss behavior; shadcn only maps a few CSS
/// variables. There's no equivalent third-party dependency to wrap here, so
/// this is a from-scratch, from-first-principles port of that same
/// behavior, not a thin wrapper.
///
/// This is the first component in this registry with a genuinely different
/// shape: every other component is a plain `View` or a presentation
/// modifier tied to a local `Binding`. A toast has to be fireable from
/// ANYWHERE — a button's `action` closure three views away from any toast
/// UI — the same way real `toast("message")` is a free function callable
/// from anywhere in the app, not a prop passed down through the tree.
/// `UI.ToastCenter` is a single `@Observable` instance, injected via
/// `EnvironmentValues` with a default instance (so it behaves like a de
/// facto app-wide singleton unless a screen explicitly overrides it via
/// `.environment(\.uiToastCenter, _:)` — e.g. for SwiftUI Previews or
/// tests that want an isolated queue). Call `.uiToastHost()` once, near
/// the app's root, to actually render the queue; call
/// `@Environment(\.uiToastCenter) private var toast` anywhere else and use
/// `toast.show(...)`/`.success(...)`/etc.
///
/// Colors for the four typed variants (`success`/`info`/`warning`/`error`)
/// are NOT from shadcn's own `--popover`/`--border` tokens — real shadcn's
/// wrapper only maps those for the DEFAULT/untyped toast. Typed toasts get
/// their color from `sonner`'s OWN internal stylesheet (fetched live from
/// `emilkowalski/sonner`'s `src/styles.css`, both its light default block
/// and its `[data-sonner-theme='dark']` block), converted HSL → sRGB by
/// hand — these are real shadcn's actual shipped toast colors, just sourced
/// from the underlying library's CSS rather than shadcn's own theme file,
/// since that's genuinely where they live.
///
/// `.loading` is a real, standalone `toast.loading(...)` call in real
/// sonner (not only used internally by `toast.promise`) — included here,
/// using the existing `UI.Spinner`. `toast.promise(...)` itself (an async
/// loading → success/error lifecycle helper) is NOT ported: it's a
/// Promise-chaining convenience with no direct Swift `async`/`await`
/// analog worth forcing into this shape — call `.show(variant: .loading)`
/// then `.dismiss(id)` + a follow-up `.success(...)` by hand instead.
public extension UI {
    enum ToastVariant: Sendable {
        case `default`, success, info, warning, error, loading
    }

    struct ToastAction: Sendable {
        public let label: String
        public let handler: @MainActor @Sendable () -> Void

        public init(_ label: String, handler: @escaping @MainActor @Sendable () -> Void) {
            self.label = label
            self.handler = handler
        }
    }

    struct ToastItem: Identifiable, Sendable {
        public let id = UUID()
        public let message: String
        public let description: String?
        public let variant: ToastVariant
        public let action: ToastAction?
    }

    /// Matches real sonner's 6 `position` options (`toast(message, {
    /// position: "top-left" }` etc., verified live against a real usage
    /// example) — set once on `.uiToastHost(position:)`, not per-toast
    /// (this port renders one host/queue per screen, same as the common
    /// real-world setup of one `<Toaster />` mounted at the app root).
    enum ToastPosition: Sendable {
        case topLeading, top, topTrailing, bottomLeading, bottom, bottomTrailing

        var alignment: Alignment {
            switch self {
            case .topLeading: .topLeading
            case .top: .top
            case .topTrailing: .topTrailing
            case .bottomLeading: .bottomLeading
            case .bottom: .bottom
            case .bottomTrailing: .bottomTrailing
            }
        }

        var isTop: Bool {
            switch self {
            case .topLeading, .top, .topTrailing: true
            case .bottomLeading, .bottom, .bottomTrailing: false
            }
        }
    }

    @MainActor
    @Observable
    final class ToastCenter {
        public private(set) var toasts: [ToastItem] = []

        // `nonisolated` so this can be constructed synchronously as an
        // `EnvironmentKey.defaultValue` (a nonisolated static context) —
        // safe, since it only initializes an empty array; every other
        // member stays `@MainActor`-isolated via the class-level annotation.
        public nonisolated init() {}

        public func show(
            _ message: String,
            description: String? = nil,
            variant: ToastVariant = .default,
            action: ToastAction? = nil,
            duration: TimeInterval = 4
        ) {
            let item = ToastItem(message: message, description: description, variant: variant, action: action)
            withAnimation(.spring(duration: 0.3)) {
                toasts.append(item)
            }
            guard duration > 0 else { return } // duration: 0 means "stays until dismissed", real sonner's own convention
            let id = item.id
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(duration))
                self?.dismiss(id)
            }
        }

        // Real shadcn/sonner's typed convenience calls: `toast.success(...)`
        // / `.info(...)` / `.warning(...)` / `.error(...)`.
        public func success(_ message: String, description: String? = nil, action: ToastAction? = nil) {
            show(message, description: description, variant: .success, action: action)
        }

        public func info(_ message: String, description: String? = nil, action: ToastAction? = nil) {
            show(message, description: description, variant: .info, action: action)
        }

        public func warning(_ message: String, description: String? = nil, action: ToastAction? = nil) {
            show(message, description: description, variant: .warning, action: action)
        }

        public func error(_ message: String, description: String? = nil, action: ToastAction? = nil) {
            show(message, description: description, variant: .error, action: action)
        }

        public func dismiss(_ id: ToastItem.ID) {
            withAnimation(.spring(duration: 0.3)) {
                toasts.removeAll { $0.id == id }
            }
        }

        public func dismissAll() {
            withAnimation(.spring(duration: 0.3)) {
                toasts.removeAll()
            }
        }
    }
}

private struct ToastCenterKey: EnvironmentKey {
    static let defaultValue = UI.ToastCenter()
}

public extension EnvironmentValues {
    var uiToastCenter: UI.ToastCenter {
        get { self[ToastCenterKey.self] }
        set { self[ToastCenterKey.self] = newValue }
    }
}

public extension View {
    /// Mount once, near the app's root — renders whatever `UI.ToastCenter`
    /// (default, app-wide instance unless overridden) is queued, stacked
    /// newest-last at `position`.
    func uiToastHost(position: UI.ToastPosition = .bottom) -> some View {
        modifier(ToastHostModifier(position: position))
    }
}

private struct ToastHostModifier: ViewModifier {
    @Environment(\.uiToastCenter) private var center
    let position: UI.ToastPosition

    func body(content: Content) -> some View {
        content.overlay(alignment: position.alignment) {
            VStack(spacing: 8) {
                ForEach(position.isTop ? center.toasts : center.toasts.reversed()) { item in
                    ToastCard(item: item) { center.dismiss(item.id) }
                        .transition(.move(edge: position.isTop ? .top : .bottom).combined(with: .opacity))
                }
            }
            .padding()
        }
    }
}

private struct ToastCard: View {
    @Environment(\.uiTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let item: UI.ToastItem
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            icon
            VStack(alignment: .leading, spacing: 2) {
                Text(item.message)
                    .font(theme.typography.label)
                    .foregroundStyle(textColor)
                if let description = item.description {
                    Text(description)
                        .font(theme.typography.body)
                        .foregroundStyle(textColor.opacity(0.8))
                }
            }
            Spacer(minLength: 0)
            if let action = item.action {
                SwiftUI.Button(action: action.handler) {
                    Text(action.label).font(theme.typography.label)
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.colors.foreground)
            }
        }
        .padding(theme.spacing.md)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                .strokeBorder(border, lineWidth: 1)
        )
        .uiShadow(theme.shadow.lg)
        .contentShape(Rectangle())
        // Real sonner's swipe-to-dismiss — a vertical drag past a threshold
        // dismisses, matching the touch-native equivalent of its own
        // pointer-drag gesture.
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if abs(value.translation.height) > 40 { onDismiss() }
                }
        )
    }

    @ViewBuilder
    private var icon: some View {
        switch item.variant {
        case .default:
            EmptyView()
        case .success:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(iconColor)
        case .info:
            Image(systemName: "info.circle.fill").foregroundStyle(iconColor)
        case .warning:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(iconColor)
        case .error:
            Image(systemName: "xmark.octagon.fill").foregroundStyle(iconColor)
        case .loading:
            UI.Spinner()
        }
    }

    private var iconColor: Color {
        switch item.variant {
        case .default, .loading: theme.colors.foreground
        case .success: .dynamic(light: Color(red: 0, green: 0.54, blue: 0.18), dark: Color(red: 0.349, green: 0.951, blue: 0.65))
        case .info: .dynamic(light: Color(red: 0.036, green: 0.45, blue: 0.864), dark: Color(red: 0.3455, green: 0.5891, blue: 0.9545))
        case .warning: .dynamic(light: Color(red: 0.864, green: 0.4638, blue: 0.036), dark: Color(red: 0.9545, green: 0.8124, blue: 0.3455))
        case .error: .dynamic(light: Color(red: 0.9, green: 0, blue: 0), dark: Color(red: 1.0, green: 0.62, blue: 0.6327))
        }
    }

    private var textColor: Color {
        switch item.variant {
        case .default, .loading: theme.colors.popoverForeground
        default: iconColor
        }
    }

    // Real sonner's per-type background/border, fetched live from its own
    // `src/styles.css` (both the light default block and the
    // `[data-sonner-theme='dark']` block) and converted HSL -> sRGB by
    // hand — NOT shadcn's own `--popover` token, which only applies to the
    // untyped/`default` toast (see this file's header comment).
    private var background: Color {
        switch item.variant {
        case .default, .loading: theme.colors.popover
        case .success: .dynamic(light: Color(red: 0.926, green: 0.994, blue: 0.9521), dark: Color(red: 0, green: 0.12, blue: 0.06))
        case .info: .dynamic(light: Color(red: 0.94, green: 0.972, blue: 1.0), dark: Color(red: 0, green: 0.05, blue: 0.12))
        case .warning: .dynamic(light: Color(red: 1.0, green: 0.989, blue: 0.94), dark: Color(red: 0.112, green: 0.12, blue: 0))
        case .error: .dynamic(light: Color(red: 1.0, green: 0.94, blue: 0.941), dark: Color(red: 0.176, green: 0.024, blue: 0.0291))
        }
    }

    private var border: Color {
        switch item.variant {
        case .default, .loading: theme.colors.border
        case .success: .dynamic(light: Color(red: 0.7504, green: 0.9896, blue: 0.8501), dark: Color(red: 0, green: 0.24, blue: 0.108))
        case .info: .dynamic(light: Color(red: 0.8663, green: 0.9066, blue: 0.9937), dark: Color(red: 0.0969, green: 0.1383, blue: 0.2431))
        case .warning: .dynamic(light: Color(red: 0.9856, green: 0.9322, blue: 0.6944), dark: Color(red: 0.18, green: 0.18, blue: 0))
        case .error: .dynamic(light: Color(red: 1.0, green: 0.88, blue: 0.882), dark: Color(red: 0.3024, green: 0.0176, blue: 0.0318))
        }
    }
}

#if DEBUG
private struct ToastPreview: View {
    @Environment(\.uiToastCenter) private var toast

    var body: some View {
        VStack(spacing: 12) {
            UI.Button("Default") { toast.show("Event has been created", description: "Sunday, December 03, 2023 at 9:00 AM") }
            UI.Button("Success", variant: .outline) { toast.success("Event has been created") }
            UI.Button("Info", variant: .outline) { toast.info("Be at the area 10 minutes early") }
            UI.Button("Warning", variant: .outline) { toast.warning("Event start time cannot be earlier than 8am") }
            UI.Button("Error", variant: .outline) { toast.error("Event has not been created") }
            UI.Button("Loading", variant: .outline) { toast.show("Uploading...", variant: .loading, duration: 0) }
            UI.Button("With action", variant: .outline) {
                toast.show("Event deleted", action: .init("Undo") { print("undo") })
            }
        }
        .padding()
        .uiToastHost()
    }
}

#Preview("Toast") {
    ToastPreview()
}
#endif
