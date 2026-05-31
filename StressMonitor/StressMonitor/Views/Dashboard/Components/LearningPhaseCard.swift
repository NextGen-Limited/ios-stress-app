import SwiftUI

/// Card component showing learning phase progress during baseline calibration
/// Displays days remaining, sample count, and progress bar
struct LearningPhaseCard: View {
    let daysRemaining: Int
    let sampleCount: Int
    let minimumSamples: Int
    let onLearnMore: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double {
        min(Double(sampleCount) / Double(minimumSamples), 1.0)
    }

    private var statusText: String {
        if daysRemaining <= 0 {
            return "Baseline Established"
        } else if sampleCount < 10 {
            return "Collecting Initial Data"
        } else {
            return "Building Your Baseline"
        }
    }

    private var statusColor: Color {
        if daysRemaining <= 0 {
            return .primaryGreen
        } else if sampleCount < 10 {
            return .warning
        } else {
            return .primaryBlue
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Learning Phase")
                            .font(.headline)
                            .foregroundColor(.white)

                        if daysRemaining > 0 {
                            Text("\(daysRemaining) days left")
                                .font(.caption.bold())
                                .foregroundColor(statusColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(statusColor.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }

                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.oledTextSecondary)
                }

                Spacer()

                // Progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.oledCardSecondary, lineWidth: 3)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            statusColor,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(
                            reduceMotion ? .none : .easeOut(duration: 0.5),
                            value: progress
                        )

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 36, height: 36)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.oledCardSecondary)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.primaryBlue, statusColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(
                            reduceMotion ? .none : .easeOut(duration: 0.5),
                            value: progress
                        )
                }
            }
            .frame(height: 8)

            // Sample count
            HStack {
                Text("\(sampleCount) of \(minimumSamples) samples")
                    .font(.caption2)
                    .foregroundColor(.oledTextSecondary)

                Spacer()

                Text("\(Int(progress * 100))% complete")
                    .font(.caption2.bold())
                    .foregroundColor(statusColor)
            }

            // Description
            Text("Individual HRV patterns vary greatly. We're learning your unique baseline to provide accurate stress insights.")
                .font(.caption)
                .foregroundColor(.oledTextSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            // Learn more button
            Button(action: onLearnMore) {
                HStack(spacing: 4) {
                    Text("How It Works")
                        .font(.subheadline)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.primaryBlue)
            }
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(20)
        .background(Color.oledCardBackground)
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Learning Phase: \(statusText). \(sampleCount) of \(minimumSamples) samples collected, \(Int(progress * 100)) percent complete.")
    }
}

// MARK: - Preview

#Preview("Learning Phase - Early") {
    ZStack {
        Color.oledBackground.ignoresSafeArea()
        LearningPhaseCard(
            daysRemaining: 7,
            sampleCount: 5,
            minimumSamples: 50,
            onLearnMore: {}
        )
        .padding()
    }
}

#Preview("Learning Phase - Mid") {
    ZStack {
        Color.oledBackground.ignoresSafeArea()
        LearningPhaseCard(
            daysRemaining: 3,
            sampleCount: 30,
            minimumSamples: 50,
            onLearnMore: {}
        )
        .padding()
    }
}

#Preview("Learning Phase - Complete") {
    ZStack {
        Color.oledBackground.ignoresSafeArea()
        LearningPhaseCard(
            daysRemaining: 0,
            sampleCount: 55,
            minimumSamples: 50,
            onLearnMore: {}
        )
        .padding()
    }
}
