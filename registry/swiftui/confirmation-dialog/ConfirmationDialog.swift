import SwiftUI

/// shadcn-swift component: confirmation-dialog
/// depends on: tokens
///
/// shadcn's AlertDialog: a blocking dialog that requires an explicit
/// confirm/cancel. Native `.confirmationDialog` already gives real modal
/// semantics and accessibility for free — this is a themed convenience
/// wrapper over it, not a reimplementation.
public extension View {
    func uiConfirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        confirmTitle: String = "Confirm",
        isDestructive: Bool = false,
        onConfirm: @escaping () -> Void
    ) -> some View {
        confirmationDialog(title, isPresented: isPresented, titleVisibility: .visible) {
            SwiftUI.Button(confirmTitle, role: isDestructive ? .destructive : nil, action: onConfirm)
            SwiftUI.Button("Cancel", role: .cancel) {}
        } message: {
            if let message {
                Text(message)
            }
        }
    }
}

#if DEBUG
private struct ConfirmationDialogPreview: View {
    @State private var isPresented = false

    var body: some View {
        Text("Host content")
            .uiConfirmationDialog(
                isPresented: $isPresented,
                title: "Delete this item?",
                message: "This can't be undone.",
                confirmTitle: "Delete",
                isDestructive: true,
                onConfirm: {}
            )
            .onAppear { isPresented = true }
    }
}

#Preview("ConfirmationDialog") {
    ConfirmationDialogPreview()
}
#endif
