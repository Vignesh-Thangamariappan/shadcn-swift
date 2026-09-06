import SwiftUI

/// Typechecked by Scripts/verify-components.sh against the real iOS SDK.
/// Exists to prove the central claim in README: `UI.Button` sits next to a bare
/// `Button` with zero ambiguity — the namespace enum never shadows SwiftUI's own
/// type — and stays true as more components (`UI.Toggle`, etc.) join it.
struct UsageProbe: View {
    @State private var text = ""
    @State private var isOn = false

    var body: some View {
        VStack {
            Button("plain SwiftUI button") {}
            UI.Button("themed button") {}
            UI.Card(title: "Hello", actionTitle: "Do it", action: {}) {
                Text("body")
            }
            UI.Badge("New", variant: .primary)
            UI.Input("Email", text: $text, isInvalid: text.isEmpty)
            Toggle("plain SwiftUI toggle", isOn: $isOn)
            UI.Toggle("themed toggle", isOn: $isOn)
        }
    }
}
