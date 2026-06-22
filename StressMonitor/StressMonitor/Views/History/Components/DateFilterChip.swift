import SwiftUI

/// Single-select date-range filter chip used on History.
///
/// Renders 7d / 30d / 90d / All. Active chip fills with the Ripple accent; inactive
/// chips are outlined. Pass the bound `DateRangeFilter` plus the chip's own range.
struct DateFilterChip: View {
    let range: DateRangeFilter
    @Binding var selected: DateRangeFilter

    private var isActive: Bool { selected == range }

    var body: some View {
        Button {
            HapticManager.shared.buttonPress()
            selected = range
        } label: {
            Text(range.label)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(0.4)
                .foregroundStyle(isActive ? Color.white : Color.Wellness.adaptivePrimaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(background)
                .overlay(
                    Capsule()
                        .stroke(
                            isActive ? Color.clear : Color.Wellness.adaptiveSecondaryText.opacity(0.28),
                            lineWidth: 1
                        )
                )
                .clipShape(Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(range.label) range")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    private var background: Color {
        isActive
            ? HomeCharacterDesignTokens.Ripple.deep
            : Color.Wellness.adaptiveCardBackground
    }
}

/// Date-range options for History filtering.
enum DateRangeFilter: String, CaseIterable, Hashable, Identifiable {
    case sevenDays    = "7d"
    case thirtyDays   = "30d"
    case ninetyDays   = "90d"
    case all          = "All"

    var id: String { rawValue }

    var label: String { rawValue }

    /// Inclusive cutoff date for this range, or nil for "All".
    func cutoff(from now: Date = Date()) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .sevenDays:  return calendar.date(byAdding: .day, value: -7, to: now)
        case .thirtyDays: return calendar.date(byAdding: .day, value: -30, to: now)
        case .ninetyDays: return calendar.date(byAdding: .day, value: -90, to: now)
        case .all:        return nil
        }
    }
}

#Preview {
    @Previewable @State var selected: DateRangeFilter = .thirtyDays
    return HStack {
        ForEach(DateRangeFilter.allCases) { range in
            DateFilterChip(range: range, selected: $selected)
        }
    }
    .padding()
    .background(Color.appBackground)
}
