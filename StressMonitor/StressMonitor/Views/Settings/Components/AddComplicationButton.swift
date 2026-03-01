import SwiftUI

/// Add complication button for watch face customization
struct AddComplicationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image("plus-icon")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)

                Text("Add Complication")
                    .font(.system(size: 14.9, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: 277)
            .frame(height: 35.5)
            .background(Color.accentTeal)
            .clipShape(Capsule())
            .shadow(AppShadow.settingsCard)
        }
        .accessibilityLabel("Add complication")
    }
}

#Preview {
    AddComplicationButton {
        print("Add complication tapped")
    }
    .padding()
    .background(Color.adaptiveSettingsBackground)
}
