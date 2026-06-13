import SwiftData
import SwiftUI

// NOTE: Baseline calibration has been removed from the onboarding flow
// in the Hybrid A+C redesign. This view is kept as a placeholder for
// backward compatibility with any existing references and tests.
// The new onboarding flow is: Welcome → Permissions → Dashboard Preview.
struct OnboardingBaselineCalibrationView: View {
    @State private var viewModel: OnboardingBaselineCalibrationViewModel

    init(repository: StressRepositoryProtocol) {
        _viewModel = State(initialValue: OnboardingBaselineCalibrationViewModel(repository: repository))
    }

    var body: some View {
        Color.clear
            .onAppear {
                // Auto-complete since baseline calibration is no longer part of onboarding
                viewModel.completeCalibration()
            }
    }
}

#Preview {
    let repository = StressRepository(
        modelContext: ModelContext((try? ModelContainer(for: StressMeasurement.self))!),
        baselineCalculator: BaselineCalculator()
    )
    OnboardingBaselineCalibrationView(repository: repository)
}
