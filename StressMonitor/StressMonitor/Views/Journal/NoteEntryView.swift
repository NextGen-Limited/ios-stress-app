import SwiftUI

// MARK: - Note Entry View

/// Simple journal entry form for daily reflections
struct NoteEntryView: View {
    @Binding var isPresented: Bool
    @State private var noteText: String = ""
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Daily Reflection")
                            .font(Typography.title2)
                            .fontWeight(.bold)

                        Text(Date(), style: .date)
                            .font(Typography.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, DesignTokens.Spacing.sm)

                    // Text Editor
                    TextEditor(text: $noteText)
                        .focused($isTextEditorFocused)
                        .font(Typography.body)
                        .frame(minHeight: 200)
                        .padding(DesignTokens.Spacing.sm)
                        .background(Color.Wellness.surface)
                        .cornerRadius(DesignTokens.Layout.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Layout.cornerRadius)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        .overlay(alignment: .topLeading) {
                            if noteText.isEmpty {
                                Text("How are you feeling today?")
                                    .font(Typography.body)
                                    .foregroundStyle(.secondary.opacity(0.5))
                                    .padding(DesignTokens.Spacing.md)
                                    .allowsHitTesting(false)
                            }
                        }

                    Spacer()
                }
                .padding(DesignTokens.Spacing.md)
            }
            .background(Color.Wellness.background)
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        HapticManager.shared.buttonPress()
                        isPresented = false
                    }
                    .accessibilityLabel("Cancel journal entry")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        HapticManager.shared.success()
                        // TODO: Implement persistence
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Save journal entry")
                }
            }
            .onAppear {
                // Auto-focus text editor after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextEditorFocused = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NoteEntryView(isPresented: .constant(true))
}
