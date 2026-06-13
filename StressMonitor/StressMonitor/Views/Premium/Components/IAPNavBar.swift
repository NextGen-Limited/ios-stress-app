import SwiftUI

struct IAPNavBar: View {
    let onBack: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack {
            // Back button — circle style
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.iapTextSecondary)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color(light: Color.white.opacity(0.62), dark: Color.white.opacity(0.06)))
                            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.iapIconBorder.opacity(0.3), lineWidth: 1)
                    )
            }

            Spacer()

            Text("StressMonitor Premium")
                .font(Typography.iapNavTitle)
                .foregroundStyle(Color.iapTextMuted)

            Spacer()

            // Close button — circle style
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.iapTextSecondary)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color(light: Color.white.opacity(0.62), dark: Color.white.opacity(0.06)))
                            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.iapIconBorder.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 8)
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()
        IAPNavBar(
            onBack: { print("Back tapped") },
            onClose: { print("Close tapped") }
        )
    }
}
