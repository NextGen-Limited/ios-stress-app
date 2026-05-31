import SwiftData
import SwiftUI

struct OnboardingBaselineCalibrationView: View {
    @State private var viewModel: OnboardingBaselineCalibrationViewModel

    init(repository: StressRepositoryProtocol) {
        _viewModel = State(initialValue: OnboardingBaselineCalibrationViewModel(repository: repository))
    }

    var body: some View {
        VStack(spacing: 24) {
            // Step indicator
            HStack {
                Text("Step 3 of 4")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step 3 of 4")

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: Double(viewModel.currentDay) / 7.0)
                    .stroke(
                        colorForPhase(viewModel.currentPhase),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: viewModel.currentDay)

                VStack(spacing: 4) {
                    Text("Day \(viewModel.currentDay)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))

                    Text("of 7")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Day \(viewModel.currentDay) of 7 calibration progress")

            // Phase information
            VStack(spacing: 16) {
                Text(phaseTitle(viewModel.currentPhase))
                    .font(.system(size: 22, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)

                Text(phaseDescription(viewModel.currentPhase))
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Daily check-in card
            if viewModel.dailyMeasurementTaken {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.stressRelaxed)
                        .font(.system(size: 24))

                    Text("Today's measurement complete")
                        .font(.system(size: 17, weight: .semibold))
                }
                .padding(16)
                .background(Color.stressRelaxed.opacity(0.1))
                .cornerRadius(12)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Today's measurement is complete")
            } else if viewModel.currentDay <= 7 {
                Button(action: { Task { await viewModel.recordDailyMeasurement() } }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Take Today's Measurement")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.primaryBlue)
                    .cornerRadius(12)
                }
                .disabled(viewModel.dailyMeasurementTaken)
                .accessibilityHint("Records daily health measurement for baseline")
            }

            Spacer()

            // Continue button (enabled after all 7 days)
            if viewModel.calibrationCompleted {
                Button(action: { viewModel.completeCalibration() }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.primaryBlue)
                        .cornerRadius(12)
                }
                .accessibilityHint("Proceeds to completion screen")
            }
        }
        .padding(24)
    }

    private func phaseTitle(_ phase: CalibrationPhase) -> String {
        switch phase {
        case .learning: return "Learning Phase"
        case .calibration: return "Calibration Phase"
        case .validation: return "Validation Phase"
        case .complete: return "Calibration Complete"
        }
    }

    private func phaseDescription(_ phase: CalibrationPhase) -> String {
        switch phase {
        case .learning:
            return "We're collecting HRV data to understand your normal patterns (Days 1-3)"
        case .calibration:
            return "Algorithm is fine-tuning to your personal patterns (Days 4-5)"
        case .validation:
            return "Baseline is being validated and finalized (Days 6-7)"
        case .complete:
            return "Your personal stress baseline is now established"
        }
    }

    private func colorForPhase(_ phase: CalibrationPhase) -> Color {
        switch phase {
        case .learning: return .stressRelaxed
        case .calibration: return .primaryBlue
        case .validation: return .stressModerate
        case .complete: return .stressRelaxed
        }
    }
}

#Preview {
    let repository = StressRepository(
        modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self)),
        baselineCalculator: BaselineCalculator()
    )
    OnboardingBaselineCalibrationView(repository: repository)
}
