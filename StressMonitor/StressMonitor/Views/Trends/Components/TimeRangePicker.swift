import SwiftUI

struct TimeRangePicker: View {
    @Binding var selectedRange: TrendsTimeRange
    let options: [TrendsTimeRange]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button(action: { selectedRange = option }) {
                    Text(option.rawValue)
                        .font(Typography.subheadline)
                        .fontWeight(selectedRange == option ? .semibold : .regular)
                        .foregroundColor(selectedRange == option ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(selectedRange == option ? Color.primaryBlue : Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
}

