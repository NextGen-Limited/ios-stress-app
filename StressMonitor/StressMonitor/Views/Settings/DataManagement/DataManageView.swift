import CloudKit
import SwiftData
import SwiftUI

/// Hub screen for data management: export, delete by range, delete all, and
/// reset. Quick destructive actions use ``DeleteConfirmationSheet`` for a
/// two-step confirmation; the detailed delete flow routes to ``DataDeleteView``.
struct DataManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    @State private var showingDeleteAll = false
    @State private var showingFactoryReset = false
    @State private var resultMessage: String?
    @State private var showingResult = false

    var body: some View {
        Form {
            recordsSection
            exportSection
            deleteSection
            resetSection
        }
        .navigationTitle("Manage Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Done", isPresented: $showingResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resultMessage ?? "")
        }
        .background(
            DeleteConfirmationSheet(
                title: "Delete all snapshots?",
                message: "Every locally stored stress measurement will be removed.",
                confirmLabel: "Delete all",
                requiresSecondaryConfirm: true,
                onConfirm: { Task { await performDeleteAll() } },
                isPresented: $showingDeleteAll
            )
        )
        .background(
            DeleteConfirmationSheet(
                title: "Factory reset?",
                message: "This wipes all data, character unlocks, and preferences.",
                confirmLabel: "Reset everything",
                requiresSecondaryConfirm: true,
                onConfirm: { Task { await performFactoryReset() } },
                isPresented: $showingFactoryReset
            )
        )
    }

    // MARK: - Records

    @ViewBuilder
    private var recordsSection: some View {
        Section("Your data") {
            HStack {
                Text("Stress snapshots")
                Spacer()
                Text("\(snapshotCount)")
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(snapshotCount) stress snapshots stored")
        }
    }

    // MARK: - Export

    private var exportSection: some View {
        Section {
            Button {
                router.settingsPath.append(Route.dataExport)
            } label: {
                rowLabel(icon: "square.and.arrow.up", tint: Color.primaryBlue, title: "Export data", subtitle: "CSV or JSON, with date range")
            }
        } header: {
            Text("Export")
        } footer: {
            Text("Share a file via the iOS share sheet. Habits export is coming soon.")
        }
    }

    // MARK: - Delete

    private var deleteSection: some View {
        Section {
            Button {
                router.settingsPath.append(Route.dataDelete)
            } label: {
                rowLabel(icon: "calendar.badge.minus", tint: .orange, title: "Delete by range", subtitle: "Remove snapshots from a window of time")
            }
            Button {
                showingDeleteAll = true
            } label: {
                rowLabel(icon: "trash", tint: Color.error, title: "Delete all snapshots", subtitle: "Removes every locally stored measurement")
            }
        } header: {
            Text("Delete")
        } footer: {
            Text("Deletions are permanent and cannot be undone.")
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        Section {
            Button {
                showingFactoryReset = true
            } label: {
                rowLabel(icon: "arrow.counterclockwise.circle", tint: Color.error, title: "Factory reset", subtitle: "Wipe all data and return the app to first launch")
            }
        } footer: {
            Text("Factory reset also clears character unlocks and preferences.")
        }
    }

    // MARK: - Row helper

    private func rowLabel(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
            Spacer()
            Image(systemName: AppIconSystem.Nav.forward.sfSymbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.5))
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    // MARK: - Derived

    private var snapshotCount: Int {
        let descriptor = FetchDescriptor<StressMeasurement>()
        return ((try? modelContext.fetchCount(descriptor)) ?? 0)
    }

    // MARK: - Actions

    /// Deletes local measurements, then mirrors the deletion to CloudKit so
    /// removed snapshots don't reappear on the next sync. CloudKit deletion
    /// failure (e.g. offline) does not roll back the local delete — it's
    /// reported separately so the user knows sync may resurrect the data.
    private func performDeleteAll() async {
        do {
            try modelContext.delete(model: StressMeasurement.self)
            try modelContext.save()
        } catch {
            resultMessage = "Delete failed: \(error.localizedDescription)"
            showingResult = true
            return
        }

        do {
            try await CloudKitResetService(container: .default(), logger: .default)
                .deleteRecords(ofType: .stressMeasurement)
            resultMessage = "All stress snapshots were deleted."
        } catch {
            resultMessage = "Local snapshots were deleted. iCloud data couldn't be removed (\(error.localizedDescription)) — it may reappear after your next sync."
        }
        showingResult = true
    }

    /// Full wipe matching the "wipes all data... and preferences" promise
    /// shown in the confirmation sheet: local measurements + character
    /// progress, CloudKit records, the stored sign-in token, and the shared
    /// App Group cache used by the widget and watch complications.
    private func performFactoryReset() async {
        do {
            try modelContext.delete(model: StressMeasurement.self)
            try modelContext.delete(model: CharacterUnlock.self)
            try modelContext.save()
        } catch {
            resultMessage = "Reset failed: \(error.localizedDescription)"
            showingResult = true
            return
        }

        SupabaseLLMService.clearStoredCredentials()
        UserDefaults(suiteName: "group.stress.ai.com")?.removePersistentDomain(forName: "group.stress.ai.com")

        do {
            try await CloudKitResetService(container: .default(), logger: .default)
                .performDatabaseReset()
            resultMessage = "Local data cleared. Relaunch the app to begin setup."
        } catch {
            resultMessage = "Local data, sign-in, and shared caches were cleared. iCloud reset failed (\(error.localizedDescription)) — relaunch the app to begin setup; remaining iCloud data will be cleared on the next sync attempt."
        }
        showingResult = true
    }
}

#Preview {
    NavigationStack {
        DataManageView()
            .stressNavigationDestinations()
    }
    .environment(AppRouter())
    .modelContainer(for: [StressMeasurement.self, CharacterUnlock.self], inMemory: true)
}
