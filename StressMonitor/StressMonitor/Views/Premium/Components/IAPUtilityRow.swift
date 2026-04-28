import SwiftUI

struct IAPUtilityRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(iconColor)
                    .frame(width: 20, height: 20)

                Text(title)
                    .font(Typography.iapUtilityLabel)
                    .foregroundStyle(Color.iapTextPrimary)
                    .tracking(-0.195)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.iapChevronGray)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(AppShadow.iapUtilityRow)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        IAPUtilityRow(
            icon: "arrow.clockwise",
            iconColor: Color.iapRestoreBlue,
            title: "Restore Purchases",
            action: {}
        )
        IAPUtilityRow(
            icon: "gearshape",
            iconColor: Color.iapManageDark,
            title: "Manage Subscription",
            action: {}
        )
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
