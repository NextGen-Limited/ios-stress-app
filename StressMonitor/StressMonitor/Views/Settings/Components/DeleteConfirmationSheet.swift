import SwiftUI

/// Two-step destructive confirmation used by the data-management flow.
///
/// Step 1: an ActionSheet offering the destructive action (or its cancel).
/// Step 2: when `requiresSecondaryConfirm` is true (e.g. "delete all"), a
/// follow-up Alert asks the user to confirm a second time with a red button.
struct DeleteConfirmationSheet: View {
    let title: String
    let message: String
    let confirmLabel: String
    let requiresSecondaryConfirm: Bool
    let onConfirm: () -> Void

    @Binding var isPresented: Bool
    @State private var showSecondaryAlert = false

    var body: some View {
        Color.clear
            .frame(height: 0)
            .confirmationDialog(
                title,
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button(confirmLabel, role: .destructive) {
                    if requiresSecondaryConfirm {
                        showSecondaryAlert = true
                    } else {
                        onConfirm()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(message)
            }
            .alert(title, isPresented: $showSecondaryAlert) {
                Button("Delete permanently", role: .destructive) {
                    onConfirm()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone. \(message)")
            }
    }
}
