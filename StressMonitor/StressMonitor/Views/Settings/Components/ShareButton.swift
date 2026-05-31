import SwiftUI

/// Share button for data export functionality
struct ShareButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image("share-icon")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)

                Text("Share")
                    .font(.system(size: 14.9, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: 277)
            .frame(height: 35.5)
            .background(Color.accentTeal)
            .clipShape(Capsule())
            .shadow(AppShadow.settingsCard)
        }
        .accessibilityLabel("Share data")
    }
}

#Preview {
    ShareButton {
        print("Share tapped")
    }
    .padding()
    .background(Color.adaptiveSettingsBackground)
}
