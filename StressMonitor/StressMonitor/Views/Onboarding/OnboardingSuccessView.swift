import Darwin
import SwiftData
import SwiftUI

struct OnboardingSuccessView: View {
    @State private var viewModel: OnboardingSuccessViewModel

    init(repository: StressRepositoryProtocol) {
        _viewModel = State(initialValue: OnboardingSuccessViewModel(repository: repository))
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success illustration
            ZStack {
                Circle()
                    .fill(Color.stressRelaxed.opacity(0.1))
                    .frame(width: 160, height: 160)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 96))
                    .foregroundColor(.stressRelaxed)

                // Confetti particles (simplified)
                ForEach(0..<8) { index in
                    Circle()
                        .fill(confettiColor(index))
                        .frame(width: 8, height: 8)
                        .offset(confettiOffset(index))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Success checkmark icon")

            // Headline
            Text("You're All Set!")
                .font(.system(size: 34, weight: .bold))
                .accessibilityAddTraits(.isHeader)

            // Summary
            VStack(spacing: 8) {
                Text("Your stress baseline is being calculated")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)

                if let baseline = viewModel.personalBaseline {
                    Text("Baseline: \(Int(baseline.baselineHRV)) ms HRV, \(Int(baseline.restingHeartRate)) bpm resting HR")
                        .font(.system(size: 13))
                        .foregroundColor(.primaryBlue)
                        .accessibilityLabel("Baseline: \(Int(baseline.baselineHRV)) milliseconds HRV, \(Int(baseline.restingHeartRate)) beats per minute resting heart rate")
                }
            }

            Spacer()

            // CTA
            Button(action: { viewModel.completeOnboarding() }) {
                Text("Go to Dashboard")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.primaryBlue)
                    .cornerRadius(12)
            }
            .accessibilityHint("Opens the main dashboard")
        }
        .padding(24)
    }

    private func confettiColor(_ index: Int) -> Color {
        let colors: [Color] = [.stressRelaxed, .primaryBlue, .stressModerate]
        return colors[index % colors.count]
    }

    private func confettiOffset(_ index: Int) -> CGSize {
        let angle = Double(index) * .pi / 4
        let distance: CGFloat = 80
        return CGSize(width: CGFloat(cos(angle)) * distance, height: CGFloat(sin(angle)) * distance)
    }
}

#Preview {
    let repository = StressRepository(
        modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self)),
        baselineCalculator: BaselineCalculator()
    )
    OnboardingSuccessView(repository: repository)
}
