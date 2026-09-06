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
    @State private var plan = "pro"
    @State private var comboSelection = ""
    @State private var showSheet = false
    @State private var showDialog = false
    @State private var showPopover = false
    @State private var showConfirm = false
    @State private var sliderValue = 0.4
    @State private var alignment = "left"
    @State private var styles: Set<String> = ["bold"]
    @State private var otpCode = ""
    @State private var fieldEmail = ""
    @State private var groupSearch = ""
    @State private var accordionExpanded: Set<String> = ["a"]
    @State private var page = 2
    @State private var showCommand = false
    @State private var selectedDate: Date? = Date()
    @State private var pickedDate: Date?
    @State private var carouselPage = 0

    var body: some View {
        VStack {
            Button("plain SwiftUI button") {}
            UI.Button("themed button") {}
            UI.Card(title: "Hello", actionTitle: "Do it", action: {}) {
                Text("body")
            }
            UI.Badge("New", variant: .default)
            UI.Input("Email", text: $text, isInvalid: text.isEmpty)
            Toggle("plain SwiftUI toggle", isOn: $isOn)
            UI.Switch("themed switch", isOn: $isOn)
            UI.Toggle(systemImage: "bold", isOn: $isOn)

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

            UI.Select(selection: $plan, options: ["free", "pro", "team"]) { $0.capitalized }
            UI.DropdownMenu("Options", items: [
                UI.MenuItem("Edit", systemImage: "pencil", action: {}),
                UI.MenuItem("Delete", systemImage: "trash", isDestructive: true, action: {})
            ])
            UI.Combobox("Framework", options: ["SwiftUI", "UIKit"], selection: $comboSelection)

            Text("Sheet trigger")
                .uiSheet(isPresented: $showSheet) { Text("Sheet content") }
            Text("Dialog trigger")
                .uiDialog(isPresented: $showDialog) { Text("Dialog content") }
            Text("Popover trigger")
                .uiPopover(isPresented: $showPopover) { Text("Popover content") }
            Text("Confirm trigger")
                .uiConfirmationDialog(isPresented: $showConfirm, title: "Are you sure?", onConfirm: {})
            Image(systemName: "info.circle")
                .uiTooltip("Tooltip text")
            Text("Long-press for context menu")
                .uiContextMenu([UI.MenuItem("Edit", action: {})])

            UI.Slider(value: $sliderValue)
            UI.Spinner()
            Color.gray.opacity(0.3).uiAspectRatio(16.0 / 9.0).frame(maxWidth: 100)
            UI.Kbd("⌘K")
            UI.Collapsible {
                Text("Advanced")
            } content: {
                Text("Hidden content")
            }
            UI.ToggleGroup(options: ["left", "center", "right"], selection: $alignment) { _ in "text.alignleft" }
            UI.ToggleGroup(options: ["bold", "italic"], selection: $styles) { $0 }
            UI.Empty(systemImage: "tray", title: "No messages", actionTitle: "Refresh", action: {})
            UI.Breadcrumb([UI.BreadcrumbItem("Home", action: {}), UI.BreadcrumbItem("Settings")])
            UI.InputOTP(length: 6, code: $otpCode)

            UI.Field("Email", description: "We'll never share it.") {
                UI.Input("you@example.com", text: $fieldEmail)
            }
            UI.Item("Wi-Fi", subtitle: "Connected", leading: {
                Image(systemName: "wifi")
            })
            UI.InputGroup("Search", text: $groupSearch, leading: {
                Image(systemName: "magnifyingglass")
            })
            UI.Accordion(
                items: [(tag: "a", title: "Section A"), (tag: "b", title: "Section B")],
                expanded: $accordionExpanded
            ) { tag in
                Text("Content \(tag)")
            }
            UI.Pagination(page: $page, totalPages: 10)
            Text("Command trigger")
                .uiCommand(isPresented: $showCommand, groups: [
                    UI.CommandGroup(items: [UI.CommandItem("New file", action: {})])
                ])

            UI.Calendar(selection: $selectedDate)
            UI.DatePicker(selection: $pickedDate)
            UI.Carousel(selection: $carouselPage, itemCount: 3) { index in
                Text("Slide \(index)")
            }
            UI.Table(columns: [UI.TableColumn("Name")], rowCount: 1) { _ in
                Text("Row")
            }
            UI.Chart(data: [UI.ChartPoint("A", value: 1), UI.ChartPoint("B", value: 2)])
        }
    }
}
