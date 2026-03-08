import SwiftUI

/// HRV Trend card with line chart visualization
/// Figma: White card with line chart showing HRV over 30 days
struct HRVTrendCard: View {
    @State private var selectedRange = "Last 7 days"

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("HRV Trend")
                        .font(.custom("Lato-Bold", size: 18))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                    Text("Last 30 days")
                        .font(.custom("Lato-Regular", size: 12))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                }

                Spacer()

                // Time range dropdown
                Menu {
                    Button("Last 7 days") { selectedRange = "Last 7 days" }
                    Button("Last 30 days") { selectedRange = "Last 30 days" }
                    Button("Last 90 days") { selectedRange = "Last 90 days" }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedRange)
                            .font(.custom("Lato-Regular", size: 12))
                            .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#E0E0E0"), lineWidth: 1)
                    )
                }
            }

            Spacer().frame(height: 8)

            // Chart area
            HStack(alignment: .top, spacing: 8) {
                // Y-axis labels
                yAxisLabels

                // Line chart
                lineChart
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .frame(width: 358, height: 406)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }

    // MARK: - Y-Axis Labels

    private var yAxisLabels: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach([150, 100, 50, 0], id: \.self) { value in
                Text("\(value)")
                    .font(.custom("Lato-Regular", size: 10))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .frame(height: 60, alignment: .top)
            }
        }
        .frame(width: 24)
    }

    // MARK: - Line Chart

    private var lineChart: some View {
        ZStack {
            // Grid lines
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<5, id: \.self) { _ in
                    Divider()
                        .frame(height: 1)
                        .background(Color(hex: "#E0E0E0"))
                        .frame(maxWidth: .infinity)
                }
            }

            // Line path (simplified representation)
            Path { path in
                let chartHeight: CGFloat = 240
                let chartWidth: CGFloat = 280

                // Sample data points forming a curve
                let points: [CGPoint] = [
                    CGPoint(x: 0, y: chartHeight * 0.33),
                    CGPoint(x: chartWidth * 0.2, y: chartHeight * 0.5),
                    CGPoint(x: chartWidth * 0.4, y: chartHeight * 0.2),
                    CGPoint(x: chartWidth * 0.6, y: chartHeight * 0.4),
                    CGPoint(x: chartWidth * 0.8, y: chartHeight * 0.1),
                    CGPoint(x: chartWidth, y: chartHeight * 0.3)
                ]

                path.move(to: points[0])
                for i in 1..<points.count {
                    path.addLine(to: points[i])
                }
            }
            .stroke(Color(hex: "#66CDAA"), lineWidth: 2.5)

            // Data points
            HStack(alignment: .bottom, spacing: 52) {
                ForEach([100, 50, 110, 80, 120, 90], id: \.self) { value in
                    Circle()
                        .fill(Color(hex: "#66CDAA"))
                        .frame(width: 6, height: 6)
                        .offset(y: CGFloat(value) - 120)
                }
            }

            // X-axis label
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("Today")
                        .font(.custom("Lato-Regular", size: 10))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                }
            }
        }
        .frame(height: 240)
    }
}

#Preview("HRVTrendCard") {
    HRVTrendCard()
        .padding()
        .background(Color.Wellness.adaptiveBackground)
}
