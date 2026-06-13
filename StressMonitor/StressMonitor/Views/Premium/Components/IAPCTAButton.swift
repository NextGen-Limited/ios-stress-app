import SwiftUI

struct IAPCTAButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard !isLoading else { return }
            action()
        }) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Text("Unlock Premium")
                            .font(Typography.iapCTA)
                            .tracking(-0.02 * 16)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.iapCTATeal, Color.iapHeaderTeal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.iapHeaderTeal.opacity(0.26), radius: 14, y: 8)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 24) {
        IAPCTAButton(isLoading: false, action: {})
        IAPCTAButton(isLoading: true, action: {})
    }
    .padding(.horizontal, 17)
    .background(Color.white)
}
