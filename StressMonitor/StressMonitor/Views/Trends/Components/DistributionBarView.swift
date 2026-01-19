import SwiftUI

struct DistributionBarView: View {
    let icon: String
    let label: String
    let percentage: Double
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(Typography.caption1)
                .foregroundColor(color)
                .frame(width: 20)

            Text(label)
                .font(Typography.caption1)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * (percentage / 100))
                }
            }
            .frame(height: 16)

            Text("\(Int(percentage))%")
                .font(Typography.caption1)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}
