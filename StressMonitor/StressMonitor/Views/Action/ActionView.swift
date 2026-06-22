import SwiftUI
import SwiftData

// MARK: - ActionView (Light Theme Redesign)
//
// Six sections matching `05-action.html`:
//   1. Header "What helps right now" — stress level + time eyebrow
//   2. Ripple recommendation hero
//   3. Breathe group → BreathingExerciseView
//   4. Move group → MiniWalkView
//   5. Reflect group → NoteEntryView (Journal) + Chat sheet
//   6. Today's habits — 3× HabitLogRow (Hydration / Sunlight AUTO, Caffeine LOG)

struct ActionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var habitViewModel: HabitViewModel?
    @State private var isChatPresented = false
    @State private var isJournalPresented = false

    /// Live stress level passed in from the Home tab. Defaults to nil
    /// (no data) — the recommendation card handles that case gracefully.
    var stressLevel: Double? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    sectionHeader
                    RippleRecommendationCard(stressLevel: stressLevel) {
                        isChatPresented = true
                    }
                    breatheGroup
                    moveGroup
                    reflectGroup
                    habitsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(HomeCharacterDesignTokens.homeBackground.ignoresSafeArea())
            .navigationTitle("Action")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isChatPresented) {
                ChatBottomSheetView(stressResult: nil, baseline: nil)
            }
            .sheet(isPresented: $isJournalPresented) {
                NoteEntryView(isPresented: $isJournalPresented)
            }
        }
        .onAppear {
            if habitViewModel == nil {
                habitViewModel = HabitViewModel(modelContext: modelContext)
            } else {
                habitViewModel?.loadToday()
            }
        }
    }

    // MARK: - 1. Header

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(timeEyebrow.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)

            Text("What helps right now")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            if let level = stressLevel {
                Text("Stress \(Int(level.rounded()))/100")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var timeEyebrow: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE • h:mm a"
        return formatter.string(from: Date())
    }

    // MARK: - 3. Breathe Group

    private var breatheGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupLabel("Breathe")
            VStack(spacing: 8) {
                ActionGroupRow(
                    icon: "wind",
                    title: "Box Breathing",
                    subtitle: "4-4-4-4 · 2 min",
                    tint: HomeCharacterDesignTokens.Ripple.primary,
                    destination: { BreathingExerciseView() }
                )
                ActionGroupRow(
                    icon: "leaf.fill",
                    title: "Calm Breathing",
                    subtitle: "4-7-8 · 3 min",
                    tint: HomeCharacterDesignTokens.Zephyr.accent,
                    destination: { BreathingExerciseView() }
                )
            }
        }
    }

    // MARK: - 4. Move Group

    private var moveGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupLabel("Move")
            ActionGroupRow(
                icon: "figure.walk",
                title: "Mini Walk",
                subtitle: "5 min nervous-system reset",
                tint: HomeCharacterDesignTokens.Blossom.accent,
                destination: { MiniWalkView() }
            )
        }
    }

    // MARK: - 5. Reflect Group

    private var reflectGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupLabel("Reflect")
            VStack(spacing: 8) {
                // NoteEntryView is sheet-presented by design (its own
                // NavigationStack + dismiss binding), so we open it as a sheet
                // rather than pushing onto this stack.
                Button {
                    HapticManager.shared.buttonPress()
                    isJournalPresented = true
                } label: {
                    journalRow
                }
                .buttonStyle(.plain)

                Button {
                    HapticManager.shared.buttonPress()
                    isChatPresented = true
                } label: {
                    reflectChatRow
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var journalRow: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HomeCharacterDesignTokens.Lumi.accent.opacity(0.14))
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HomeCharacterDesignTokens.Lumi.accent)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("Journal")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Text("Capture one stressor")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.10), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Journal. Capture one stressor.")
        .accessibilityHint("Double tap to write a reflection")
    }

    private var reflectChatRow: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HomeCharacterDesignTokens.Ripple.primary.opacity(0.14))
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("Talk to Ripple")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Text("AI coach for what's on your mind")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.10), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Talk to Ripple. AI coach for what's on your mind.")
        .accessibilityHint("Double tap to open chat")
    }

    // MARK: - 6. Today's Habits

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupLabel("Today's habits")
            VStack(spacing: 8) {
                ForEach(HabitType.allCases) { type in
                    if let habit = habitViewModel?.habit(for: type) {
                        HabitLogRow(habit: habit) {
                            habitViewModel?.logManual(type)
                        }
                    } else {
                        HabitLogRow(habit: Habit(type: type)) {
                            habitViewModel?.logManual(type)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func groupLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            .padding(.leading, 4)
    }
}

// MARK: - Previews

#Preview {
    ActionView(stressLevel: 62)
}

#Preview("No Stress Data") {
    ActionView()
}
