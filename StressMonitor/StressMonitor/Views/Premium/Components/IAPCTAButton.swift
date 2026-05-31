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
                    Text("Unlock Premium")
                        .font(Typography.iapCTA)
                        .foregroundStyle(.white)
                        .tracking(-0.21)
                }
            }
            .frame(width: 242, height: 40)
            .background(Color.iapCTATeal)
            .clipShape(Capsule())
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
    .padding()
    .background(Color.white)
}
