import SwiftUI

/// shadcn-swift component: combobox
/// depends on: tokens
///
/// Self-contained View: owns its own `@State private var isPresented` and
/// presents its own `.sheet` internally, so the portal problem dissolves the
/// same way it does for select/dropdown-menu — the caller just gets a plain
/// View, no external Binding to manage.
public extension UI {
    struct Combobox: View {
        @Environment(\.uiTheme) private var theme
        @State private var isPresented = false
        @State private var query = ""

        private let placeholder: String
        private let options: [String]
        @Binding private var selection: String

        public init(_ placeholder: String = "Select...", options: [String], selection: Binding<String>) {
            self.placeholder = placeholder
            self.options = options
            self._selection = selection
        }

        public var body: some View {
            SwiftUI.Button {
                isPresented = true
            } label: {
                HStack {
                    Text(selection.isEmpty ? placeholder : selection)
                        .foregroundStyle(selection.isEmpty ? theme.colors.foreground.opacity(0.4) : theme.colors.foreground)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.colors.foreground.opacity(0.5))
                }
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
                .background(theme.colors.background)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                        .strokeBorder(theme.colors.input, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    List(filtered, id: \.self) { option in
                        SwiftUI.Button {
                            selection = option
                            isPresented = false
                        } label: {
                            HStack {
                                Text(option)
                                Spacer()
                                if option == selection {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundStyle(theme.colors.foreground)
                    }
                    .searchable(text: $query)
                    .navigationTitle(placeholder)
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .large])
            }
        }

        private var filtered: [String] {
            query.isEmpty ? options : options.filter { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}

#if DEBUG
private struct ComboboxPreview: View {
    @State private var framework = ""

    var body: some View {
        UI.Combobox("Select framework", options: ["SwiftUI", "UIKit", "Compose", "React"], selection: $framework)
            .padding()
    }
}

#Preview("Combobox") {
    ComboboxPreview()
}
#endif
