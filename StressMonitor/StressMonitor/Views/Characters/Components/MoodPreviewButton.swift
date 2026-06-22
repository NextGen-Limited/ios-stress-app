import SwiftUI

struct MoodPreviewButton: View {
    let mood: RippleMood
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: mood.symbol)
                    .font(.title3)
                Text(mood.displayName)
                    .font(Typography.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isSelected ? .white : Color.Wellness.adaptivePrimaryText)
            .frame(width: 72, height: 64)
            .background(isSelected ? color : Color.Wellness.adaptiveCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? color : Color.borderLight.opacity(0.7), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mood.accessibilityDescription)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
