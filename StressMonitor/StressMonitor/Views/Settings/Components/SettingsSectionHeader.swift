import SwiftUI

/// Section header for Settings cards with icon and title
struct SettingsSectionHeader: View {
    let icon: String?
    let iconImage: String?
    let title: String
    let color: Color

    init(icon: String? = nil, iconImage: String? = nil, title: String, color: Color = .settingsRippleBlue) {
        self.icon = icon
        self.iconImage = iconImage
        self.title = title
        self.color = color
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.16))

                if let imageName = iconImage {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(color)
                        .frame(width: 20, height: 20)
                } else if let systemIcon = icon {
                    Image(systemName: systemIcon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(color)
                }
            }
            .frame(width: 34, height: 34)

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct SettingsSectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            SettingsSectionHeader(iconImage: "watch-icon", title: "Watch face & Complications", color: .settingsRippleBlue)
            SettingsSectionHeader(icon: "gear", title: "General Settings", color: .settingsIconPurple)
        }
        .padding()
    }
}
