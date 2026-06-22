import SwiftUI

/// Multi-select stress-category filter chip used on History.
///
/// Color-coded per category. Tapping toggles membership in the bound set.
/// An empty selected set means "all categories shown" (default).
struct CategoryFilterChip: View {
    let category: StressCategory
    @Binding var selected: Set<StressCategory>

    private var isActive: Bool { selected.contains(category) }

    var body: some View {
        Button {
            HapticManager.shared.buttonPress()
            if isActive {
                selected.remove(category)
            } else {
                selected.insert(category)
            }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.stressColor(for: category))
                    .frame(width: 8, height: 8)
                Text(category.rawValue.capitalized)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(0.3)
                    .foregroundStyle(isActive ? Color.white : Color.Wellness.adaptivePrimaryText)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(background)
            .overlay(border)
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.rawValue.capitalized) category filter")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    private var background: Color {
        if isActive {
            return Color.stressColor(for: category)
        }
        return Color.Wellness.adaptiveCardBackground
    }

    private var border: some View {
        Capsule()
            .stroke(
                isActive ? Color.clear : Color.Wellness.adaptiveSecondaryText.opacity(0.28),
                lineWidth: 1
            )
    }
}

#Preview {
    @Previewable @State var selected: Set<StressCategory> = [.mild]
    return ScrollView(.horizontal, showsIndicators: false) {
        HStack {
            ForEach(StressCategory.allCases, id: \.self) { category in
                CategoryFilterChip(category: category, selected: $selected)
            }
        }
        .padding()
    }
    .background(Color.appBackground)
}
