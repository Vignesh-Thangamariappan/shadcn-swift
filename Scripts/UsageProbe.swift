import SwiftUI

/// Typechecked by Scripts/verify-components.sh against the real iOS SDK.
/// Exists to prove the central claim in README: `UI.Button` sits next to a bare
/// `Button` with zero ambiguity — the namespace enum never shadows SwiftUI's own
/// type — and stays true as more components join it.
struct UsageProbe: View {
    @State private var text = ""
    @State private var longText = ""
    @State private var isOn = false
    @State private var isChecked = false
    @State private var radioSelection = "a"
    @State private var tab = "profile"

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

            UI.Label("Themed label")
            UI.Separator()
            UI.Avatar(name: "Ada Lovelace")
            UI.ProgressBar(value: 0.4)
            UI.Skeleton().frame(height: 16)
            UI.Checkbox("Accept terms", isOn: $isChecked)
            UI.RadioGroup(options: ["a", "b", "c"], selection: $radioSelection) { $0 }
            UI.Alert("Heads up", message: "Something happened.", variant: .destructive)
            UI.TextArea("Write something...", text: $longText)
            UI.Tabs(
                items: [(tag: "profile", title: "Profile"), (tag: "settings", title: "Settings")],
                selection: $tab
            ) { selected in
                Text("Content for \(selected)")
            }
        }
    }
}
