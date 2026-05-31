import SwiftUI

struct MiniWalkView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MiniWalkViewModel()

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Spacer()
            MiniWalkTimerRing(
                progress: viewModel.progress,
                timeDisplay: viewModel.timeDisplay,
                isRunning: viewModel.isRunning
            )
            MiniWalkInstructionCard(text: viewModel.instruction)
                .padding(.top, 24)
            Spacer()
            actionButtons
                .padding(.bottom, 40)
        }
        .background(Color.Wellness.adaptiveBackground)
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onDisappear { viewModel.cleanup() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.gray)
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 0.75)
                    )
            }
            .accessibilityLabel("Back")

            Spacer()

            Text("Mini Walk")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !viewModel.isRunning {
                Button(action: { viewModel.start() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start")
                            .font(.system(size: 20, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 152, height: 58)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.Wellness.tealCard))
                }
            }

            Button(action: { viewModel.reset() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundStyle(Color.Wellness.tealCard)
                .frame(width: 152, height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(.systemGray4), lineWidth: 1)
                )
            }
            .disabled(!viewModel.isRunning && !viewModel.isFinished)
        }
    }
}

#Preview {
    NavigationStack {
        MiniWalkView()
    }
}
