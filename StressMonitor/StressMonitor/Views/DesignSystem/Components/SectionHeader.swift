import SwiftUI

struct SectionHeader: View {
    let title: String
    var icon: String?
    var action: (() -> Void)?
    var actionText: String = "See All"

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.primaryBlue)
            }

            Text(title)
                .font(Typography.title2)
                .fontWeight(.bold)

            Spacer()

            if let action = action {
                Button(action: action) {
                    Text(actionText)
                        .font(Typography.subheadline)
                        .foregroundColor(.primaryBlue)
                }
            }
        }
    }
}
