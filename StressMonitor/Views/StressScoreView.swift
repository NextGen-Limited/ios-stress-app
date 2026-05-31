import SwiftUI

/// Welltory-inspired circular stress score gauge.
/// Displays a radial progress indicator with color-coded stress levels,
/// animated transitions, and supporting metrics.
struct StressScoreView: View {
    let score: Double           // 0.0 - 1.0
    let category: HRVAnalyzer.StressCategory
    let coherence: Double       // 0.0 - 1.0
    let hrv: Double             // Latest HRV (SDNN) in ms
    let heartRate: Double       // Latest HR in BPM
    let trend: Double           // Positive = stress increasing

    @State private var animatedScore: Double = 0
    @State private var isAnimating = false

    // MARK: - Constants

    private let gaugeLineWidth: CGFloat = 20
    private let gaugeSize: CGFloat = 220

    var body: some View {
        VStack(spacing: 16) {
            // Main gauge
            ZStack {
                // Background track
                Circle()
                    .stroke(
                        Color.gray.opacity(0.15),
                        style: StrokeStyle(lineWidth: gaugeLineWidth, lineCap: .round)
                    )
                    .frame(width: gaugeSize, height: gaugeSize)

                // Colored progress arc
                Circle()
                    .trim(from: 0, to: animatedScore)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: stressColors),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * animatedScore)
                        ),
                        style: StrokeStyle(lineWidth: gaugeLineWidth, lineCap: .round)
                    )
                    .frame(width: gaugeSize, height: gaugeSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: animatedScore)

                // Center content
                VStack(spacing: 4) {
                    Text(scoreDisplayText)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(stressColor)
                        .contentTransition(.numericText())

                    Text(category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(stressColor.opacity(0.8))

                    // Trend indicator
                    HStack(spacing: 4) {
                        Image(systemName: trendIcon)
                            .font(.caption)
                            .foregroundColor(trendColor)
                        Text(trendText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Metrics row
            HStack(spacing: 24) {
                MetricPill(
                    icon: "waveform.path.ecg",
                    label: "HRV",
                    value: String(format: "%.0f ms", hrv),
                    color: .blue
                )

                MetricPill(
                    icon: "heart.fill",
                    label: "HR",
                    value: String(format: "%.0f bpm", heartRate),
                    color: .red
                )

                MetricPill(
                    icon: "brain.head.profile",
                    label: "Coherence",
                    value: String(format: "%.0f%%", coherence * 100),
                    color: .purple
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedScore = score
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeInOut(duration: 0.6)) {
                animatedScore = newValue
            }
        }
    }

    // MARK: - Computed Properties

    private var scoreDisplayText: String {
        // Convert to Welltory-style 0-100 scale
        String(format: "%.0f", score * 100)
    }

    private var stressColors: [Color] {
        switch category {
        case .resting:  return [.green, .mint]
        case .low:      return [.blue, .cyan]
        case .moderate: return [.yellow, .orange]
        case .high:     return [.orange, .red]
        case .veryHigh: return [.red, .purple]
        }
    }

    private var stressColor: Color {
        stressColors.first ?? .green
    }

    private var trendIcon: String {
        if trend > 0.02 { return "arrow.up.right" }
        if trend < -0.02 { return "arrow.down.right" }
        return "arrow.right"
    }

    private var trendColor: Color {
        if trend > 0.02 { return .red }
        if trend < -0.02 { return .green }
        return .secondary
    }

    private var trendText: String {
        if trend > 0.02 { return "Rising" }
        if trend < -0.02 { return "Falling" }
        return "Stable"
    }
}

// MARK: - Metric Pill

/// Small metric display used below the gauge.
struct MetricPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(value)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Stress Level Badge

/// Compact badge showing stress category with color coding.
struct StressLevelBadge: View {
    let category: HRVAnalyzer.StressCategory

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(badgeColor)
                .frame(width: 8, height: 8)

            Text(category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.15))
        .cornerRadius(12)
    }

    private var badgeColor: Color {
        switch category {
        case .resting:  return .green
        case .low:      return .blue
        case .moderate: return .yellow
        case .high:     return .orange
        case .veryHigh: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        StressScoreView(
            score: 0.42,
            category: .moderate,
            coherence: 0.65,
            hrv: 45,
            heartRate: 72,
            trend: 0.03
        )

        StressLevelBadge(category: .moderate)
    }
    .padding()
}
