import SwiftUI

/// Watch **Home** screen.
///
/// A character-reactive face: the Ripple 💧 emoji changes expression based on
/// the current stress level. **No numeric score is ever shown** — the face and
/// its accent colour *are* the indicator. A "Measure" button triggers a fresh
/// HealthKit reading via the existing `WatchStressViewModel`.
struct WatchHomeView: View {
    @Bindable var viewModel: WatchStressViewModel

    var body: some View {
        VStack(spacing: 10) {
            characterFace

            // A single non-numeric mood word anchors the expression.
            Text(currentTier.label)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(currentTier.accent)
                .contentTransition(.opacity)

            if viewModel.isLoading {
                ProgressView()
                    .tint(currentTier.accent)
            } else {
                Button {
                    Task { await viewModel.measureStress() }
                } label: {
                    Label("Measure", systemImage: "heart.text.square")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
                .buttonStyle(.bordered)
                .tint(currentTier.accent)
                .disabled(viewModel.isLoading)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 9))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StressCharacterPalette.darkCanvas.ignoresSafeArea())
        .task {
            await viewModel.requestAuthorization()
            await viewModel.loadLatestStress()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var characterFace: some View {
        if viewModel.isLoading {
            CharacterFaceView(tier: currentTier, size: 120, glow: true)
                .opacity(0.6)
        } else {
            CharacterFaceView(tier: currentTier, size: 120, glow: true)
                .startIdleAnimation()
        }
    }

    private var currentTier: StressTier {
        StressTier.from(level: viewModel.currentLevel)
    }
}

#if DEBUG
#Preview {
    let vm = WatchStressViewModel()
    return WatchHomeView(viewModel: vm)
}
#endif
