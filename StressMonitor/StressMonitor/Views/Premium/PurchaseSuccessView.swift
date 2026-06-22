import SwiftData
import SwiftUI

/// Confirmation screen shown after a successful Premium purchase.
///
/// Unlocks the premium characters (Ember, Zephyr) and the streak-gated Lumi
/// by updating existing `CharacterUnlock` rows additively, then renders the
/// newly-available SwiftUI character views at 80pt.
struct PurchaseSuccessView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Character ids unlocked by Premium.
    private static let unlockedByPremium = ["ember", "zephyr", "lumi"]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header

                unlockedCharactersPreview

                benefitsList

                actions
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .background(HomeCharacterDesignTokens.homeBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(HomeCharacterDesignTokens.Ripple.light.opacity(0.32))
                    .frame(width: 110, height: 110)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color(hex: "#4FC01B"))
            }
            .accessibilityHidden(true)

            Text("Welcome to Premium")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            Text("All five elemental companions are now yours, along with trends, AI coaching, and deeper recovery insights.")
                .font(.subheadline)
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Unlocked Characters

    private var unlockedCharactersPreview: some View {
        VStack(spacing: 12) {
            Text("New companions unlocked")
                .font(.headline)
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            HStack(spacing: 16) {
                ForEach(Self.unlockedByPremium, id: \.self) { id in
                    if let creature = CharacterCreature.find(by: id) {
                        characterChip(creature: creature)
                    }
                }
            }
        }
        .task { unlockPremiumCharacters() }
    }

    private func characterChip(creature: CharacterCreature) -> some View {
        VStack(spacing: 6) {
            CharacterAssetResolver.characterView(for: creature.id, mood: .happy, size: 80)
            Text(creature.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
            Text(creature.subtitle)
                .font(.system(size: 11))
                .foregroundStyle(creature.element.accentColor)
        }
        .frame(width: 96)
        .padding(.vertical, 10)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(creature.element.primaryColor.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(creature.displayName), \(creature.subtitle), now unlocked")
    }

    // MARK: - Benefits

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Trends: HRV, distribution, and recovery patterns")
            benefitRow(icon: "bubble.left.and.bubble.right.fill", text: "AI coaching with Ripple")
            benefitRow(icon: "sparkles", text: "All elemental companions and evolution stages")
            benefitRow(icon: "icloud.fill", text: "CloudKit sync across your devices")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HomeCharacterDesignTokens.Ripple.deep)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Text("Back to Home")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(HomeCharacterDesignTokens.Ripple.deep)
            .accessibilityLabel("Back to Home")

            Button {
                Task { await restoreOrDismiss() }
            } label: {
                Text("Restore purchases")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
            .accessibilityLabel("Restore purchases")
        }
        .padding(.top, 8)
    }

    // MARK: - Unlock Logic

    /// Additively mark the premium-gated characters as unlocked. Existing rows
    /// are updated in place; missing rows (unexpected on a seeded store) are
    /// inserted so the unlock always lands.
    private func unlockPremiumCharacters() {
        let descriptor = FetchDescriptor<CharacterUnlock>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        let byId = Dictionary(uniqueKeysWithValues: existing.map { ($0.characterId, $0) })

        for id in Self.unlockedByPremium {
            if let row = byId[id] {
                guard !row.isUnlocked else { continue }
                row.isUnlocked = true
                row.unlockedAt = Date()
            } else {
                let row = CharacterUnlock(characterId: id, isUnlocked: true, currentEvolution: .droplet)
                modelContext.insert(row)
            }
        }

        try? modelContext.save()
    }

    private func restoreOrDismiss() async {
        // Restore is handled by StoreKitService elsewhere; here we simply return
        // the user home since the purchase is already confirmed on this screen.
        dismiss()
    }
}

#Preview {
    PurchaseSuccessView()
        .modelContainer(for: CharacterUnlock.self, inMemory: true)
}
