import SwiftUI

/// Watch **Tier Name Editor** screen — rename the four primary stress
/// tiers with custom labels. Bound to `UserDefaults` via
/// `TierNamePreferences`.
///
/// Editing a label updates the underlying `TierNamePreferences` struct
/// and persists immediately. The `.severe` tier is intentionally not
/// editable to preserve its safety-critical default label.
struct TierNameEditorView: View {
    @State private var preferences: TierNamePreferences = .load()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 5) {
                Text("CUSTOM TIER NAMES")
                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                    .tracking(0.06 * 8.5)
                    .foregroundStyle(WatchDesignTokens.muted)

                VStack(spacing: 0) {
                    tierRow(.relaxed)
                    divider
                    tierRow(.mild)
                    divider
                    tierRow(.moderate)
                    divider
                    tierRow(.high)
                }
                .background(
                    RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                        .fill(WatchDesignTokens.surface)
                )
            }
            .padding(.horizontal, WatchDesignTokens.contentSidePadding)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .background(WatchDesignTokens.canvas.ignoresSafeArea())
        .navigationTitle("Tier Names")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Rows

    private func tierRow(_ category: WatchStressCategory) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tierSwatch(for: category))
                .frame(width: 7, height: 7)
            Text(label(for: category))
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(0.04 * 9)
                .foregroundStyle(WatchDesignTokens.muted)
                .frame(width: 56, alignment: .leading)
            TextField(defaultName(for: category), text: binding(for: category))
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(WatchDesignTokens.ink)
                .submitLabel(.done)
                .onChange(of: binding(for: category).wrappedValue) { _, _ in
                    preferences.save()
                }
        }
        .padding(.horizontal, WatchDesignTokens.Spacing.xs)
        .padding(.vertical, 6)
    }

    private var divider: some View {
        Divider()
            .frame(height: WatchDesignTokens.hairlineThickness)
            .background(WatchDesignTokens.separator)
    }

    // MARK: - Helpers

    private func binding(for category: WatchStressCategory) -> Binding<String> {
        switch category {
        case .relaxed:  return Binding(
            get: { preferences.relaxed },
            set: { preferences.relaxed = $0 })
        case .mild:     return Binding(
            get: { preferences.mild },
            set: { preferences.mild = $0 })
        case .moderate: return Binding(
            get: { preferences.moderate },
            set: { preferences.moderate = $0 })
        case .high:     return Binding(
            get: { preferences.high },
            set: { preferences.high = $0 })
        case .severe:   return .constant("Severe")
        }
    }

    private func label(for category: WatchStressCategory) -> String {
        switch category {
        case .relaxed:  return "RELAXED"
        case .mild:     return "MILD"
        case .moderate: return "MODERATE"
        case .high:     return "HIGH"
        case .severe:   return "SEVERE"
        }
    }

    private func defaultName(for category: WatchStressCategory) -> String {
        switch category {
        case .relaxed:  return "Relaxed"
        case .mild:     return "Mild"
        case .moderate: return "Moderate"
        case .high:     return "High"
        case .severe:   return "Severe"
        }
    }

    private func tierSwatch(for category: WatchStressCategory) -> Color {
        switch category {
        case .relaxed:  return WatchDesignTokens.accent
        case .mild:     return Color(hex: "#007AFF")
        case .moderate: return Color(hex: "#FFD60A")
        case .high:     return Color(hex: "#FF9500")
        case .severe:   return Color(hex: "#FF3B30")
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        TierNameEditorView()
    }
}
#endif
