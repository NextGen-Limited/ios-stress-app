import SwiftUI

/// Consent sheet for health-data syncing: explains what leaves the device
/// (daily averages only, never raw samples) and records the grant via
/// `PUT /health/consent` before the first upload. The server row is the
/// consent authority — "Allow" only persists after the PUT succeeds.
struct HealthConsentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var working = false
    @State private var failed = false
    var onDecision: (Bool) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.red)
            Text("Sync Health Data?")
                .font(.title2.bold())
            Text(
                "Upload a daily summary of your heart-rate variability, average heart rate, and resting heart rate so your coach can track stress over time.\n\nOnly daily averages leave your device — never raw samples. You can turn this off anytime in Settings."
            )
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            if failed {
                Text("Couldn't reach the server. Try again later.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            HStack(spacing: 16) {
                Button("Not Now") { onDecision(false); dismiss() }
                    .buttonStyle(.bordered)
                Button {
                    working = true
                    Task {
                        do {
                            try await StressAPIClient().setHealthConsent(true)
                            HealthSyncService.shared.markConsentGranted()
                            onDecision(true)
                            dismiss()
                        } catch {
                            failed = true
                            working = false
                        }
                    }
                } label: {
                    if working { ProgressView() } else { Text("Allow") }
                }
                .buttonStyle(.borderedProminent)
                .disabled(working)
            }
        }
        .padding(32)
    }
}
