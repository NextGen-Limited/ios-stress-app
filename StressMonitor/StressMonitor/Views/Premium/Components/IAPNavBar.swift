import SwiftUI

struct IAPNavBar: View {
    let onBack: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack {
            // Back button
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.iapTextPrimary)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.iapIconBorder, lineWidth: 0.75)
                    )
            }

            Spacer()

            Text("Premium")
                .font(Typography.iapNavTitle)
                .foregroundStyle(Color.iapTextMuted)

            Spacer()

            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.iapTextPrimary)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.iapIconBorder, lineWidth: 0.75)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
