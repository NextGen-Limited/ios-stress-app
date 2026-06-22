import SwiftData
import SwiftUI

/// View for exporting all character illustrations as a ZIP archive.
/// Shows a gallery preview grid with filtering, a progress indicator during export,
/// and a share sheet on completion.
struct CharacterIllustrationExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exporter = CharacterIllustrationExporter()
    @State private var selectedElement: CharacterElement?
    @State private var selectedEvolution: EvolutionStage?
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var exportSize: CGFloat = 512

    // MARK: - Filtering

    private var filteredIllustrations: [(creature: CharacterCreature, evolution: EvolutionStage, mood: RippleMood)] {
        CharacterIllustrationExporter.allIllustrations.filter { item in
            let matchesElement = selectedElement == nil || item.creature.element == selectedElement
            let matchesEvolution = selectedEvolution == nil || item.evolution == selectedEvolution
            return matchesElement && matchesEvolution
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Filters
            filterSection
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            // Content
            if exporter.isExporting {
                exportProgressView
            } else {
                illustrationGallery
            }
        }
        .background(Color.Wellness.adaptiveBackground.ignoresSafeArea())
        .navigationTitle("Export Characters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .disabled(exporter.isExporting)
            }
            ToolbarItem(placement: .confirmationAction) {
                if exporter.isExporting {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button("Export All") {
                        Task { await performExport() }
                    }
                    .disabled(filteredIllustrations.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .alert("Export Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        VStack(spacing: 10) {
            // Element filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: "All", element: nil)
                    ForEach(CharacterElement.allCases, id: \.self) { element in
                        filterChip(title: element.emoji + " " + element.displayName, element: element)
                    }
                }
            }

            // Evolution filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterEvolutionChip(title: "All Stages", evolution: nil)
                    ForEach(EvolutionStage.allCases, id: \.self) { stage in
                        filterEvolutionChip(title: stage.displayName, evolution: stage)
                    }
                }
            }

            // Count summary
            HStack {
                Text("\(filteredIllustrations.count) illustrations")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                Spacer()
                Text("\(CharacterIllustrationExporter.allIllustrations.count) total")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private func filterChip(title: String, element: CharacterElement?) -> some View {
        let isSelected = selectedElement == element
        let color = element?.primaryColor ?? Color.primaryBlue

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                selectedElement = element
            }
            HapticManager.shared.buttonPress()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Color.Wellness.adaptivePrimaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.Wellness.adaptiveCardBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(color.opacity(isSelected ? 0 : 0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func filterEvolutionChip(title: String, evolution: EvolutionStage?) -> some View {
        let isSelected = selectedEvolution == evolution

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                selectedEvolution = evolution
            }
            HapticManager.shared.buttonPress()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Color.Wellness.adaptivePrimaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.primaryBlue : Color.Wellness.adaptiveCardBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.primaryBlue.opacity(isSelected ? 0 : 0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Gallery

    private var illustrationGallery: some View {
        ScrollView {
            // Group by character
            let grouped = Dictionary(grouping: filteredIllustrations) { $0.creature.id }
            let sortedKeys = grouped.keys.sorted()

            LazyVStack(spacing: 24) {
                ForEach(sortedKeys, id: \.self) { characterId in
                    if let creature = CharacterCreature.find(by: characterId),
                       let items = grouped[characterId] {
                        characterSection(creature: creature, items: items)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
    }

    private func characterSection(
        creature: CharacterCreature,
        items: [(creature: CharacterCreature, evolution: EvolutionStage, mood: RippleMood)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Text(creature.emoji)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(creature.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    Text(creature.subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                }
                Spacer()
                Text("\(items.count) imgs")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Color.secondary.opacity(0.1))
                    )
            }

            // Group by evolution stage
            let byEvolution = Dictionary(grouping: items) { $0.evolution }
            let sortedStages = byEvolution.keys.sorted { $0.sortOrder < $1.sortOrder }

            ForEach(sortedStages, id: \.self) { evolution in
                if let moodItems = byEvolution[evolution] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(evolution.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(creature.element.accentColor)

                        // Grid of mood illustrations
                        let columns = Array(
                            repeating: GridItem(.flexible(), spacing: 8),
                            count: min(moodItems.count, 5)
                        )
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(moodItems, id: \.mood) { item in
                                illustrationCell(creature: creature, evolution: evolution, mood: item.mood)
                            }
                        }
                    }
                }
            }
        }
    }

    private func illustrationCell(
        creature: CharacterCreature,
        evolution: EvolutionStage,
        mood: RippleMood
    ) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(creature.element.primaryColor.opacity(0.08))
                    .frame(width: 60, height: 60)

                StressBuddyIllustration(
                    characterId: creature.id,
                    evolution: evolution,
                    mood: mood,
                    size: 44
                )
            }

            Text(mood.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .lineLimit(1)
        }
    }

    // MARK: - Export Progress

    private var exportProgressView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: max(exporter.progress, 0.001))
                    .stroke(
                        AngularGradient(
                            colors: [Color.primaryBlue, Color(hex: "#A5D6A7"), Color.primaryBlue],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.82), value: exporter.progress)

                VStack(spacing: 4) {
                    Text("\(Int(exporter.progress * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                    Text("\(exporter.completedItems)/\(exporter.totalItems)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.secondary)
                }
            }

            VStack(spacing: 8) {
                Text("Exporting Characters")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                Text(exporter.currentOperation)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Export Action

    private func performExport() async {
        do {
            let url = try await exporter.exportAll()
            await MainActor.run {
                exportURL = url
                showingShareSheet = true
                HapticManager.shared.success()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                HapticManager.shared.error()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CharacterIllustrationExportView()
    }
    .modelContainer(for: CharacterUnlock.self, inMemory: true)
}
