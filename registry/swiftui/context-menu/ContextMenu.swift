import SwiftUI

/// shadcn-swift component: context-menu
/// depends on: tokens, dropdown-menu (reuses UI.MenuItem — one item model,
/// not two, since dropdown-menu and context-menu are the same "list of
/// actions" shape triggered two different ways)
///
/// Thin wrapper over native `.contextMenu` (long-press reveal) — SwiftUI
/// already owns the presentation, so there's no portal problem here either.
/// Preview limitation: `.contextMenu` has no `isPresented` binding to flip
/// from `.onAppear` the way uiSheet/uiDialog/uiPopover do, so this file's
/// #Preview shows only the trigger at rest — long-press it on a real device
/// or simulator to see the revealed menu.
public extension View {
    func uiContextMenu(_ items: [UI.MenuItem]) -> some View {
        contextMenu {
            ForEach(items) { item in
                SwiftUI.Button(role: item.isDestructive ? .destructive : nil, action: item.action) {
                    if let systemImage = item.systemImage {
                        SwiftUI.Label(item.title, systemImage: systemImage)
                    } else {
                        Text(item.title)
                    }
                }
            }
        }
    }
}

#if DEBUG
private struct ContextMenuPreview: View {
    var body: some View {
        Text("Long-press me")
            .padding()
            .uiContextMenu([
                UI.MenuItem("Edit", systemImage: "pencil", action: {}),
                UI.MenuItem("Delete", systemImage: "trash", isDestructive: true, action: {})
            ])
    }
}

#Preview("ContextMenu") {
    ContextMenuPreview()
}
#endif
