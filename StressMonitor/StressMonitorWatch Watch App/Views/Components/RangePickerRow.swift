import SwiftUI

// MARK: - HistoryRange

/// Time range filter for the History tab.
enum HistoryRange: String, CaseIterable, Identifiable {
    case week      // 7 days
    case month     // 30 days
    case quarter   // 90 days

    var id: String { rawValue }

    /// User-facing short label rendered inside the segmented control.
    var shortLabel: String {
        switch self {
        case .week:    return "7D"
        case .month:   return "30D"
        case .quarter: return "90D"
        }
    }

    /// Day count for the range.
    var dayCount: Int {
        switch self {
        case .week:    return 7
        case .month:   return 30
        case .quarter: return 90
        }
    }
}

// MARK: - RangePickerRow

/// Segmented control for the 7D / 30D / 90D History ranges.
///
/// Three pill segments inside a hairlined surface well; the selected
/// segment is filled with accent-strong and uses white text. Uses the
/// iOS DS motion defaults (snappy ease, honors reduce-motion).
struct RangePickerRow: View {
    @Binding var selectedRange: HistoryRange

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 2) {
            ForEach(HistoryRange.allCases) { range in
                segment(range)
            }
        }
        .padding(3)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusControl, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusControl, style: .continuous)
                .stroke(WatchDesignTokens.separator, lineWidth: WatchDesignTokens.hairlineThickness)
        )
        .accessibilityElement()
        .accessibilityLabel("History range, \(selectedRange.shortLabel) selected")
    }

    // MARK: - Subviews

    @ViewBuilder
    private func segment(_ range: HistoryRange) -> some View {
        let isSelected = selectedRange == range
        Button {
            selectedRange = range
        } label: {
            Text(range.shortLabel)
                .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(isSelected ? .white : WatchDesignTokens.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 26)
                .background(
                    RoundedRectangle(cornerRadius: WatchDesignTokens.radiusControl - 3, style: .continuous)
                        .fill(isSelected ? WatchDesignTokens.accentStrong : .clear)
                )
                .animation(
                    WatchDesignTokens.motion(WatchDesignTokens.Motion.fast, reduceMotion: reduceMotion),
                    value: isSelected
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(range.shortLabel) range\(isSelected ? ", selected" : "")")
    }
}

#if DEBUG
#Preview("Range picker") {
    struct PreviewWrapper: View {
        @State private var range: HistoryRange = .week
        var body: some View {
            RangePickerRow(selectedRange: $range)
                .padding()
                .background(WatchDesignTokens.canvas)
        }
    }
    return PreviewWrapper()
}
#endif
