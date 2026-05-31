import SwiftUI
import SwiftData

struct BreathingSessionView: View {
    @State private var viewModel: BreathingSessionViewModel?
    @Environment(\.dismiss) private var dismiss
    @State private var showSummary = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: breathingGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                HStack {
                    Spacer()

                    Button(action: {
                        viewModel?.endSession()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.trailing)

                Spacer()

                if let viewModel = viewModel {
                    BreathingCircleView(
                        phase: viewModel.breathingPhase,
                        scale: viewModel.circleScale,
                        color: breathingColor
                    )
                    .frame(height: 320)
                }

                VStack(spacing: 8) {
                    Text(instructionText)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(subtitleText)
                        .font(Typography.body)
                        .foregroundColor(.secondary)
                }
                .animation(.easeInOut, value: viewModel?.breathingPhase)

                Spacer()

                Text(timeRemainingText)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Button(action: {
                    viewModel?.endSession()
                    showSummary = true
                }) {
                    Text("End Session")
                        .font(Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.secondary.opacity(0.3))
                        .cornerRadius(26)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            viewModel = BreathingSessionViewModel()
            viewModel?.startSession()
        }
        .onDisappear {
            viewModel?.endSession()
        }
        .navigationDestination(isPresented: $showSummary) {
            if let result = viewModel?.sessionResult {
                BreathingSummaryView(result: result)
            }
        }
    }

    private var breathingGradient: [Color] {
        @Environment(\.colorScheme) var colorScheme
        if colorScheme == .dark {
            return [
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color(red: 0.05, green: 0.05, blue: 0.1)
            ]
        } else {
            return [
                Color(red: 0.97, green: 0.97, blue: 0.98),
                Color.white
            ]
        }
    }

    private var breathingColor: Color {
        guard let phase = viewModel?.breathingPhase else { return .stressRelaxed }
        switch phase {
        case .inhale:
            return .stressRelaxed
        case .hold:
            return .stressMild
        case .exhale:
            return .stressRelaxed.opacity(0.6)
        }
    }

    private var instructionText: String {
        guard let viewModel = viewModel else { return "" }
        switch viewModel.breathingPhase {
        case .inhale: return "Inhale..."
        case .hold: return "Hold..."
        case .exhale: return "Exhale..."
        }
    }

    private var subtitleText: String {
        guard let viewModel = viewModel else { return "" }
        switch viewModel.breathingPhase {
        case .inhale: return "Deeply through your nose"
        case .hold: return "Gently hold"
        case .exhale: return "Slowly out through your mouth"
        }
    }

    private var timeRemainingText: String {
        guard let viewModel = viewModel else { return "02:00" }
        let minutes = Int(viewModel.remainingTime) / 60
        let seconds = Int(viewModel.remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
