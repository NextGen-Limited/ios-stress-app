import SwiftUI

struct HealthKitErrorView: View {
    @State private var viewModel = HealthKitErrorViewModel()

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Error icon
            ZStack {
                Circle()
                    .fill(Color.stressHigh.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.stressHigh)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Access denied icon")

            // Headline
            Text("Health Access Required")
                .font(.system(size: 28, weight: .bold))
                .accessibilityAddTraits(.isHeader)

            // Explanation
            Text("Please grant health permissions in Settings to continue using StressMonitor")
                .font(.system(size: 17))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button(action: { viewModel.openSettings() }) {
                    Text("Open Settings")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.primaryBlue)
                        .cornerRadius(12)
                }
                .accessibilityHint("Opens iOS Settings app")

                Button(action: { viewModel.dismissToWelcome() }) {
                    Text("Cancel")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .accessibilityHint("Returns to welcome screen")
            }
        }
        .padding(24)
    }
}

#Preview {
    HealthKitErrorView()
}
