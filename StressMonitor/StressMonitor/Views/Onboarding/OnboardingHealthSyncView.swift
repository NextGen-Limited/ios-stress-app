import SwiftUI

struct OnboardingHealthSyncView: View {
    @State private var viewModel = OnboardingHealthSyncViewModel()

    var body: some View {
        VStack(spacing: 24) {
            // Step indicator
            HStack {
                Text("Step 2 of 4")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step 2 of 4")

            // Hero icon
            ZStack {
                Circle()
                    .fill(Color.primaryBlue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.primaryBlue)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Health data access icon")

            // Title and description
            VStack(spacing: 8) {
                Text("Health Data Access")
                    .font(.system(size: 28, weight: .bold))
                    .accessibilityAddTraits(.isHeader)

                Text("We need access to your health data to calculate stress levels")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Data type cards
            VStack(spacing: 12) {
                DataTypeCard(
                    icon: "heart.fill",
                    color: .red,
                    title: "Heart Rate",
                    description: "Resting and active measurements"
                )
                DataTypeCard(
                    icon: "waveform.path",
                    color: .purple,
                    title: "Heart Rate Variability",
                    description: "Primary stress indicator"
                )
                DataTypeCard(
                    icon: "bed.double.fill",
                    color: .blue,
                    title: "Sleep Analysis",
                    description: "Recovery quality tracking"
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Health data types we access")

            Spacer()

            // Privacy note
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.stressRelaxed)
                    .font(.system(size: 12))
                    .accessibilityHidden(true)

                Text("Your data stays on your device. We never sell your information.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Privacy assurance: Your data stays on your device")

            // Continue button
            Button(action: { Task { await viewModel.requestHealthKitAuthorization() } }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Authorize & Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(viewModel.isLoading ? Color.gray : Color.primaryBlue)
            .cornerRadius(12)
            .disabled(viewModel.isLoading)
            .accessibilityHint("Requests health kit authorization")
        }
        .padding(24)
        .alert("Authorization Error", isPresented: .constant(viewModel.authorizationError != nil)) {
            Button("OK") {
                viewModel.authorizationError = nil
            }
        } message: {
            if let error = viewModel.authorizationError {
                Text(error)
            }
        }
    }
}

struct DataTypeCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.stressRelaxed)
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(description)")
    }
}

#Preview {
    OnboardingHealthSyncView()
}
