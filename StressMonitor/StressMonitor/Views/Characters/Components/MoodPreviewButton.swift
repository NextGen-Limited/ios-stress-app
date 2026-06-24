import SwiftUI

// MARK: - Mood Preview Grid

/// 5-cell mood grid matching `17-character-detail.html`.
///
/// Shows 5 stress-level mood cells (0–25, 26–50, 51–75, 76–90, 91+)
/// each with a colored face circle and SF Symbol expression.
/// Tapping a cell previews that mood on the character hero.
struct MoodPreviewGrid: View {
    let creature: CharacterCreature
    @Binding var selectedMood: RippleMood

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(StressMoodCell.allCases.enumerated()), id: \.element) { _, cell in
                moodCell(cell)
            }
        }
    }

    @ViewBuilder
    private func moodCell(_ cell: StressMoodCell) -> some View {
        let isSelected = cell.mood == selectedMood

        VStack(spacing: 4) {
            // Face circle with SF Symbol expression
            ZStack {
                Circle()
                    .fill(cell.color)
                    .frame(width: 28, height: 28)

                Image(systemName: cell.symbol)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            }
            .overlay {
                if isSelected {
                    Circle()
                        .stroke(creature.element.primaryColor, lineWidth: 2)
                        .frame(width: 32, height: 32)
                }
            }

            Text(cell.rangeLabel)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(0.4)
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 64)
        .padding(.vertical, 8)
        .background(cell.color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                selectedMood = cell.mood
            }
            HapticManager.shared.buttonPress()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cell.label), range \(cell.rangeLabel)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Stress Mood Cell

/// Maps stress categories to mood display metadata, matching the HTML grid.
enum StressMoodCell: String, CaseIterable {
    case relaxed    // 0–25
    case mild       // 26–50
    case moderate   // 51–75
    case high       // 76–90
    case severe     // 91+

    var mood: RippleMood {
        switch self {
        case .relaxed:  return .relaxed
        case .mild:     return .serene
        case .moderate: return .focused
        case .high:     return .worried
        case .severe:   return .determined
        }
    }

    var color: Color {
        switch self {
        case .relaxed:  return Color(hex: "#34C759")
        case .mild:     return Color(hex: "#007AFF")
        case .moderate: return Color(hex: "#FFD60A")
        case .high:     return Color(hex: "#FF9500")
        case .severe:   return Color(hex: "#FF3B30")
        }
    }

    /// SF Symbol face expression matching the HTML SVG paths.
    var symbol: String {
        switch self {
        case .relaxed:  return "face.smiling"           // smile, eyes
        case .mild:     return "face.dashed"             // neutral
        case .moderate: return "face.dashed.fill"        // flat
        case .high:     return "face.touched"            // worried
        case .severe:   return "face.touched.fill"       // frown
        }
    }

    var rangeLabel: String {
        switch self {
        case .relaxed:  return "0–25"
        case .mild:     return "26–50"
        case .moderate: return "51–75"
        case .high:     return "76–90"
        case .severe:   return "91+"
        }
    }

    var label: String {
        switch self {
        case .relaxed:  return "Relaxed"
        case .mild:     return "Mild"
        case .moderate: return "Moderate"
        case .high:     return "High"
        case .severe:   return "Severe"
        }
    }
}
