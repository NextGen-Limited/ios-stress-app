import SwiftUI

/// Small widget view (16x16 modules)
/// Displays stress ring and current stress level
@available(iOS 17.0, *)
public struct SmallWidgetView: View {

    let entry: StressEntry

    public init(entry: StressEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(spacing: 0) {
            if entry.isPlaceholder {
                placeholderView
            } else if let stress = entry.latestStress {
                stressContent(stress: stress)
            } else {
                emptyStateView
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Stress Content

    @ViewBuilder
    private func stressContent(stress: StressData) -> some View {
        VStack(spacing: 4) {
            // Stress ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: stress.level / 100)
                    .stroke(
                        colorForLevel(stress.level),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: stress.level)

                // Category icon
                Image(systemName: stress.stressCategory.icon)
                    .font(.system(size: 20))
                    .foregroundColor(colorForLevel(stress.level))
            }
            .frame(width: 52, height: 52)

            // Stress level
            Text("\(Int(stress.level))")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            // Category label
            Text(stress.stressCategory.displayName.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)
        }
        .padding(12)
    }

    // MARK: - Placeholder View

    private var placeholderView: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 6)

                Image(systemName: "waveform.path")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
            .frame(width: 52, height: 52)

            Text("--")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)

            Text("LOADING")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)
        }
        .padding(12)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)

            Text("No Data")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)

            Text("Open app to measure")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
    }

    // MARK: - Helpers

    private func colorForLevel(_ level: Double) -> Color {
        switch level {
        case 0...25: return Color(hex: "#34C759")
        case 26...50: return Color(hex: "#007AFF")
        case 51...75: return Color(hex: "#FFD60A")
        case 76...100: return Color(hex: "#FF9500")
        default: return .secondary
        }
    }
}

// MARK: - Color Extension for Widget

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    SmallWidgetView(entry: StressEntry(
        date: Date(),
        latestStress: StressData(
            level: 35,
            category: "mild",
            hrv: 55,
            heartRate: 68,
            confidence: 0.85,
            timestamp: Date()
        ),
        history: [],
        baseline: (50.0, 60.0),
        isPlaceholder: false
    ))
} timeline: {
    StressEntry(
        date: Date(),
        latestStress: StressData(
            level: 35,
            category: "mild",
            hrv: 55,
            heartRate: 68,
            confidence: 0.85,
            timestamp: Date()
        ),
        history: [],
        baseline: (50.0, 60.0),
        isPlaceholder: false
    )
}
