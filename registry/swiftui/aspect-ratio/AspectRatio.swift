import SwiftUI

/// shadcn-swift component: aspect-ratio
/// depends on: (none — no theme, no state; a genuine passthrough)
///
/// Real shadcn's AspectRatio is itself a thin Radix passthrough — HTML/CSS
/// needs an explicit trick to hold a ratio. SwiftUI's native
/// `.aspectRatio(_:contentMode:)` already IS that trick, so this is a
/// faithful 1:1 port: a named wrapper for API parity/discoverability, not
/// new behavior. `ui`-prefixed like every other modifier here, so it can't
/// collide with the native modifier of nearly the same signature.
public extension View {
    func uiAspectRatio(_ ratio: CGFloat, contentMode: ContentMode = .fit) -> some View {
        aspectRatio(ratio, contentMode: contentMode)
    }
}

#if DEBUG
private struct AspectRatioPreview: View {
    var body: some View {
        Color.gray.opacity(0.3)
            .uiAspectRatio(16.0 / 9.0)
            .frame(maxWidth: 240)
            .padding()
    }
}

#Preview("AspectRatio") {
    AspectRatioPreview()
}
#endif
