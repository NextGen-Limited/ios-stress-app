import SwiftUI

struct CharacterDetailView: View {
    let creature: CharacterCreature
    let unlock: CharacterUnlock?
    var onSelect: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var previewMood: RippleMood = .serene

    private var isUnlocked: Bool { unlock?.isUnlocked ?? false }
    private var isActive: Bool { unlock?.isActive ?? false }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    characterHero

                    if isUnlocked {
                        moodPreviewSection
                    }

                    infoSection
                    evolutionSection

                    if isUnlocked, let unlock {
                        statsSection(unlock: unlock)
                        selectButton
                    } else {
                        unlockCTA
                    }
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.Wellness.adaptiveBackground.ignoresSafeArea())
            .navigationTitle(creature.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var characterHero: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [creature.element.primaryColor.opacity(0.32), .clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 130
                    )
                )
                .frame(width: 250, height: 250)

            if isUnlocked {
                StressBuddyIllustration(
                    characterId: creature.id,
                    evolution: unlock?.evolutionStage ?? .droplet,
                    mood: previewMood,
                    size: 150
                )
            } else {
                Image(systemName: AppIconSystem.System.locked.sfSymbol)
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(creature.element.primaryColor.opacity(0.55))
            }
        }
        .accessibilityHidden(true)
    }

    private var moodPreviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Mood Preview", icon: "face.smiling")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(RippleMood.allCases, id: \.self) { mood in
                        MoodPreviewButton(
                            mood: mood,
                            isSelected: previewMood == mood,
                            color: creature.element.primaryColor
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                previewMood = mood
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var infoSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(creature.emoji)
                        .font(.title2)
                    Text(creature.subtitle)
                        .font(Typography.headline)
                    Spacer()
                }

                Text(creature.description)
                    .font(Typography.body)
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

                Divider()

                Label(creature.personality, systemImage: "sparkles")
                    .font(Typography.caption1)
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
        }
    }

    private var evolutionSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Evolution", icon: "arrow.triangle.2.circlepath")

                ForEach(EvolutionStage.allCases, id: \.self) { stage in
                    EvolutionTimelineRow(
                        stage: stage,
                        requirement: creature.evolutionRequirement(for: stage),
                        isComplete: isUnlocked && (unlock?.evolutionStage.sortOrder ?? -1) >= stage.sortOrder,
                        isCurrent: isUnlocked && unlock?.evolutionStage == stage,
                        color: creature.element.accentColor
                    )
                }
            }
        }
    }

    private func statsSection(unlock: CharacterUnlock) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Stats", icon: "chart.bar.fill")

                HStack(spacing: Spacing.lg) {
                    StatItem(label: "Streak", value: "\(unlock.streakDays)d", icon: "flame.fill", color: .orange)
                    StatItem(label: "Sessions", value: "\(unlock.sessionsCompleted)", icon: "figure.mind.and.body", color: .teal)
                    StatItem(label: "Resilience", value: "\(Int(unlock.resilienceScore))", icon: "shield.fill", color: .blue)
                }
            }
        }
    }

    private var selectButton: some View {
        Button {
            onSelect?()
        } label: {
            Label(isActive ? "Active Character" : "Use \(creature.displayName)", systemImage: isActive ? "checkmark.circle.fill" : "person.crop.circle.badge.checkmark")
                .font(Typography.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.borderedProminent)
        .tint(creature.element.primaryColor)
        .disabled(isActive)
    }

    private var unlockCTA: some View {
        GlassCard {
            VStack(spacing: Spacing.md) {
                if creature.unlockType == .premium {
                    Image(systemName: AppIconSystem.System.premium.sfSymbol)
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("Premium Character")
                        .font(Typography.headline)
                    Text("Unlock with StressMonitor Premium")
                        .font(Typography.body)
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    Button("Get Premium") { }
                        .buttonStyle(.borderedProminent)
                } else if creature.unlockType == .streakGated {
                    Image(systemName: AppIconSystem.Metric.streak.sfSymbol)
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("\(creature.streakRequired)-Day Streak Required")
                        .font(Typography.headline)
                    Text("Keep logging daily to unlock \(creature.displayName)!")
                        .font(Typography.body)
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }
}
