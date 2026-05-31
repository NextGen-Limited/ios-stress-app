import SwiftUI

struct BreathingSummaryView: View {
    let result: BreathingSessionResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 32)

                ZStack {
                    Circle()
                        .fill(Color.stressRelaxed.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.stressRelaxed)
                }

                Text("Session Complete")
                    .font(Typography.title1)
                    .fontWeight(.bold)

                improvementCard

                BeforeAfterChart(
                    beforeValue: result.preSessionHRV,
                    afterValue: result.postSessionHRV
                )
                .padding(.horizontal, 24)

                stressChangeBadge

                Spacer()

                VStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(Typography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.primaryBlue)
                            .cornerRadius(26)
                    }
                    .padding(.horizontal, 24)

                    Button(action: { shareResult() }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Result")
                        }
                        .font(Typography.subheadline)
                        .foregroundColor(.primaryBlue)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color.backgroundLight)
        .navigationBarHidden(true)
    }

    private var improvementCard: some View {
        VStack(spacing: 16) {
            Text("HRV Improvement")
                .font(Typography.headline)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(sign)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(improvementColor)

                Text("\(Int(abs(result.improvement)))ms")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundColor(improvementColor)

                Text("(\(Int(result.percentageImprovement))%)")
                    .font(Typography.title3)
                    .foregroundColor(.secondary)
            }

            Text("Based on pre- and post-session measurements")
                .font(Typography.caption1)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondary.opacity(0.1))
        )
        .padding(.horizontal, 24)
    }

    private var stressChangeBadge: some View {
        HStack(spacing: 8) {
            VStack(spacing: 4) {
                Text("Before")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: stressIcon(for: .high))
                        .font(Typography.caption1)

                    Text("Elevated")
                        .font(Typography.caption1)
                        .strikethrough()
                }
                .foregroundColor(.stressHigh)
            }

            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                Text("After")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: stressIcon(for: .mild))
                        .font(Typography.caption1)

                    Text("Normal")
                        .font(Typography.caption1)
                }
                .foregroundColor(.stressMild)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
        .padding(.horizontal, 24)
    }

    private var sign: String {
        result.improvement >= 0 ? "+" : ""
    }

    private var improvementColor: Color {
        switch result.stressChange {
        case .improved: return .stressRelaxed
        case .stable: return .stressMild
        case .declined: return .stressHigh
        }
    }

    private func stressIcon(for category: StressCategory) -> String {
        Color.stressIcon(for: category)
    }

    private func shareResult() {
        let text = """
        Breathing Session Complete 🧘

        Duration: \(Int(result.duration / 60)) minutes
        Cycles: \(result.cyclesCompleted)

        HRV Improvement: \(sign)\(Int(result.improvement))ms (\(Int(result.percentageImprovement))%)
        """

        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
