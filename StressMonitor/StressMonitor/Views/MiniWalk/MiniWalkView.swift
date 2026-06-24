import SwiftUI

struct MiniWalkView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MiniWalkViewModel()

    var body: some View {
        ZStack {
            // Dark canvas #0A0A0F
            HomeCharacterDesignTokens.darkCanvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                Spacer(minLength: 8)
                WalkTimer(
                    progress: viewModel.progress,
                    stepCount: viewModel.stepCount,
                    paceDisplay: viewModel.paceDisplay
                )
                MiniWalkInstructionCard(progress: viewModel.progress)
                    .padding(.top, 20)
                Spacer(minLength: 8)
                statsRow
                    .padding(.top, 8)
                actionButtons
                    .padding(.top, 24)
                    .padding(.bottom, 40)
            }

            // Completion overlay
            if viewModel.showComplete {
                MiniWalkCompleteView(viewModel: viewModel) {
                    viewModel.showComplete = false
                    viewModel.reset()
                    dismiss()
                } onTrends: {
                    viewModel.showComplete = false
                    dismiss()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showComplete)
        .navigationBarHidden(true)
        .onDisappear { viewModel.cleanup() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: AppIconSystem.Nav.back.sfSymbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "#9CA3AF"))
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.75)
                        )
                }
                .accessibilityLabel("Back")

                Spacer()

                Text("Mini Walk")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#E0E0E8"))

                Spacer()

                Color.clear.frame(width: 36, height: 36)
            }

            // Subtitle: "10 min · Brisk pace"
            Text("10 min · Brisk pace")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#9CA3AF"))
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Stats Row (Steps / BPM / kcal)

    private var statsRow: some View {
        HStack(spacing: 12) {
            WalkStatView(
                icon: "figure.walk",
                value: viewModel.stepDisplay,
                label: "Steps"
            )
            WalkStatView(
                icon: "heart.fill",
                value: viewModel.bpmDisplay,
                label: "BPM"
            )
            WalkStatView(
                icon: "flame.fill",
                value: viewModel.calorieDisplay,
                label: "kcal"
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !viewModel.isRunning && !viewModel.isPaused {
                // Start button — accent gradient
                Button(action: { viewModel.start() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start Walk")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        HomeCharacterDesignTokens.Ripple.primary,
                                        HomeCharacterDesignTokens.Ripple.deep
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: HomeCharacterDesignTokens.Ripple.primary.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal, 20)
            } else {
                // Pause / Resume button — accent gradient
                Button(action: {
                    if viewModel.isPaused { viewModel.start() } else { viewModel.pause() }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        Text(viewModel.isPaused ? "Resume" : "Pause")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        HomeCharacterDesignTokens.Ripple.primary,
                                        HomeCharacterDesignTokens.Ripple.deep
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: HomeCharacterDesignTokens.Ripple.primary.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal, 20)
            }

            // End Walk — glass card button
            Button(action: { viewModel.reset() }) {
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                    Text("End Walk")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color(hex: "#9CA3AF"))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(HomeCharacterDesignTokens.darkCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            .disabled(!viewModel.isRunning && !viewModel.isPaused && !viewModel.isFinished)
            .opacity((!viewModel.isRunning && !viewModel.isPaused && !viewModel.isFinished) ? 0.4 : 1.0)
        }
    }
}

// MARK: - Walk Stat Cell

private struct WalkStatView: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#E0E0E8"))
                .monospacedDigit()
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#9CA3AF"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(HomeCharacterDesignTokens.darkCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        MiniWalkView()
    }
}
