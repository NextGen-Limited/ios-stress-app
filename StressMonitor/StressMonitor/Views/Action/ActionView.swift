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
                VStack(alignment: .leading, spacing: 18) {
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
            if let level = stressLevel {
                let category = StressResult.category(for: level).displayName
                Text("Now · \(category) \(Int(level.rounded())) · \(timeEyebrow)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            } else {
                Text(timeEyebrow.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }

            Text("What helps right now")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var timeEyebrow: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    // MARK: - 3. Breathe Group

    private var breatheGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupLabel("Breathe", hint: "90s — 2 min")
            ActionGroupCard {
                VStack(spacing: 0) {
                    ActionGroupRow(
                        icon: "wind",
                        title: "Box Breathing",
                        subtitle: "4-4-4-4 · 2 min · ~14% HRV lift",
                        tint: HomeCharacterDesignTokens.Ripple.primary,
                        destination: { BreathingExerciseView() }
                    )
                    ActionRowDivider()
                    ActionGroupRow(
                        icon: "brain.head.profile",
                        title: "Body Scan",
                        subtitle: "90s · somatic reset · head to feet",
                        tint: HomeCharacterDesignTokens.Zephyr.accent,
                        destination: { BreathingExerciseView() }
                    )
                }
            }
        }
    }

    // MARK: - 4. Move Group

    private var moveGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupLabel("Move", hint: "30s — 5 min")
            ActionGroupCard {
                VStack(spacing: 0) {
                    ActionGroupRow(
                        icon: "figure.walk",
                        title: "Mini Walk",
                        subtitle: "5 min · target 600 steps",
                        tint: Color(hex: "#34C759"),
                        destination: { MiniWalkView() }
                    )
                    ActionRowDivider()
                    ActionGroupRow(
                        icon: "drop.fill",
                        title: "Cold Splash",
                        subtitle: "30s · vagus nerve reset",
                        tint: HomeCharacterDesignTokens.Ember.accent,
                        destination: { BreathingExerciseView() }
                    )
                }
            }
        }
    }

    // MARK: - 5. Reflect Group

    private var reflectGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupLabel("Reflect", hint: "2 — 5 min")
            ActionGroupCard {
                VStack(spacing: 0) {
                    // NoteEntryView is sheet-presented (its own NavigationStack +
                    // dismiss binding), so we open it as a sheet rather than push.
                    reflectRow(
                        icon: "face.smiling",
                        title: "Gratitude",
                        subtitle: "3-line journal · what went well today",
                        tint: Color(hex: "#FE9901"),
                        action: {
                            HapticManager.shared.buttonPress()
                            isJournalPresented = true
                        }
                    )
                    ActionRowDivider()
                    reflectRow(
                        icon: "bubble.left",
                        title: "Talk to Ripple",
                        subtitle: "Process today's stressor · 5 min",
                        tint: HomeCharacterDesignTokens.Ripple.primary,
                        action: {
                            HapticManager.shared.buttonPress()
                            isChatPresented = true
                        }
                    )
                }
            }
        }
    }

    /// A reflect row — same layout as ActionGroupRow but driven by a Button
    /// (sheet presentation) rather than a NavigationLink push.
    private func reflectRow(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.55))
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("Double tap to open")
    }

    // MARK: - 6. Today's Habits

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupLabel("Today's habits", hint: "Tap to log")
            ActionGroupCard {
                VStack(spacing: 0) {
                    ForEach(Array(HabitType.allCases.enumerated()), id: \.element) { idx, type in
                        if idx > 0 { ActionRowDivider() }
                        let habit = habitViewModel?.habit(for: type) ?? Habit(type: type)
                        HabitLogRow(habit: habit) {
                            habitViewModel?.logManual(type)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Group label with optional right-aligned hint — matches HTML `.group-label`.
    @ViewBuilder
    private func groupLabel(_ title: String, hint: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            Spacer(minLength: 0)
            if let hint = hint {
                Text(hint)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.7))
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }
}

// MARK: - Previews

#Preview {
    ActionView(stressLevel: 62)
}

#Preview("No Stress Data") {
    ActionView()
}
