import SwiftUI

/// Widget placeholder for watch complications and data sharing options
struct ComplicationWidget: View {
    let title: String
    let icon: String?

    init(title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        VStack(spacing: 6) {
            // Widget preview (85x44)
            ZStack {
                RoundedRectangle(cornerRadius: 10.9)
                    .fill(Color.adaptiveCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.9)
                            .stroke(Color.widgetBorder, lineWidth: 0.91)
                    )

                // Placeholder content
                VStack(spacing: 4) {
                    if let iconName = icon {
                        Image(systemName: iconName)
                            .font(.system(size: 12))
                            .foregroundColor(.accentTeal)
                    } else {
                        Circle()
                            .fill(Color.widgetBorder)
                            .frame(width: 21, height: 21)
                    }

                    // Skeleton bars
                    RoundedRectangle(cornerRadius: 10.9)
                        .fill(Color.widgetBorder)
                        .frame(width: 31, height: 3.6)
                    RoundedRectangle(cornerRadius: 10.9)
                        .fill(Color.widgetBorder)
                        .frame(width: 25, height: 3.6)
                }
            }
            .frame(width: 85.6, height: 43.7)

            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)
        }
        .frame(width: 147.5, height: 112.9)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.borderLight, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) widget placeholder")
    }
}

#Preview {
    HStack(spacing: 23) {
        ComplicationWidget(title: "Circular")
        ComplicationWidget(title: "Graphic")
    }
    .padding()
    .background(Color.adaptiveSettingsBackground)
}
