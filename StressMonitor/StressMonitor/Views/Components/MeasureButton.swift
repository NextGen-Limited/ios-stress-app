import SwiftUI

struct MeasureButton: View {
    let isLoading: Bool
    let title: String
    let action: () async -> Void

    @State private var isTriggering = false

    init(isLoading: Bool = false, title: String = "Measure Now", action: @escaping () async -> Void) {
        self.isLoading = isLoading
        self.title = title
        self.action = action
    }

    var body: some View {
        Button {
            trigger()
        } label: {
            HStack {
                if isLoading || isTriggering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else {
                    Text(title)
                        .font(.system(size: DesignTokens.Typography.body, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Layout.minTouchTarget)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Layout.cornerRadius))
        }
        .disabled(isLoading || isTriggering)
        .accessibilityLabel("Measure stress now")
        .accessibilityHint(isLoading ? "Measuring stress level" : "Tap to measure current stress level")
    }

    private func trigger() {
        isTriggering = true
        Task {
            await action()
            isTriggering = false
        }
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.lg) {
        MeasureButton(isLoading: false) {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        MeasureButton(isLoading: true) {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }
    .padding()
}
