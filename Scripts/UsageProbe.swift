import SwiftUI

/// Typechecked by Scripts/verify-components.sh against the real iOS SDK.
/// Exists to prove the central claim in README: `UI.Button` sits next to a bare
/// `Button` with zero ambiguity — the namespace enum never shadows SwiftUI's own type.
struct UsageProbe: View {
    var body: some View {
        VStack {
            Button("plain SwiftUI button") {}
            UI.Button("themed button") {}
            UI.Card(title: "Hello", actionTitle: "Do it", action: {}) {
                Text("body")
            }
        }
    }
}
