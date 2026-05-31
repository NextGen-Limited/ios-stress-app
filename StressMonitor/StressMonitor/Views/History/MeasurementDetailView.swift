import SwiftUI
import SwiftData

struct MeasurementDetailView: View {
    let measurement: StressMeasurement
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DetailViewModel?
    @Environment(\.dismiss) private var dismiss

    init(measurement: StressMeasurement) {
        self.measurement = measurement
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                stressLevelCard
                    .padding(.horizontal)

                hrvMeasurementsCard
                    .padding(.horizontal)

                contributingFactorsCard
                    .padding(.horizontal)

                if let viewModel = viewModel, !viewModel.recommendations.isEmpty {
                    recommendationsCard
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color.backgroundLight)
        .navigationBarHidden(true)
        .overlay(navigationBar)
        .task {
            viewModel = DetailViewModel(measurement: measurement, modelContext: modelContext)
            await viewModel?.loadData()
        }
    }

    private var navigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.primary)
            }

            Spacer()

            Text(formatDate(measurement.timestamp))
                .font(Typography.headline)

            Spacer()

            Button(action: { viewModel?.shareMeasurement() }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundColor(.primaryBlue)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    private var stressLevelCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: iconForCategory(category))
                    .font(.title3)

                Text(categoryTitle(category))
                    .font(Typography.headline)
            }
            .foregroundColor(colorForCategory(category))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(colorForCategory(category).opacity(0.15))
            .cornerRadius(20)

            StressGaugeView(
                level: measurement.stressLevel,
                category: category
            )

            if let confidences = measurement.confidences, !confidences.isEmpty {
                let avgConfidence = confidences.reduce(0, +) / Double(confidences.count)
                HStack {
                    Label("\(Int(avgConfidence * 100))% Confidence", systemImage: "checkmark.circle.fill")
                        .font(Typography.caption1)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(formatTime(measurement.timestamp))
                        .font(Typography.caption1)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    private var hrvMeasurementsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HRV Measurements")
                .font(Typography.headline)

            VStack(spacing: 12) {
                HRVRow(
                    label: "Current HRV",
                    value: "\(Int(measurement.hrv)) ms",
                    icon: "heart.fill",
                    color: .red
                )

                Divider()

                HRVRow(
                    label: "Today's Average",
                    value: todayAvgText,
                    icon: "calendar",
                    color: .primaryBlue
                )

                Divider()

                HRVRow(
                    label: "Weekly Average",
                    value: weeklyAvgText,
                    icon: "chart.bar",
                    color: .stressRelaxed
                )

                Divider()

                HRVRow(
                    label: "Baseline Range",
                    value: baselineRangeText,
                    icon: "scale.3d",
                    color: .stressModerate
                )

                if let trend = viewModel?.trend {
                    Divider()

                    HStack {
                        Image(systemName: trendIcon(trend))
                            .foregroundColor(trendColor(trend))

                        Text(trendText(trend))
                            .font(Typography.body)

                        Spacer()

                        Text("\(Int(viewModel?.percentile ?? 0))th percentile")
                            .font(Typography.caption1)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    private var contributingFactorsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contributing Factors")
                .font(Typography.headline)

            VStack(spacing: 16) {
                ForEach(viewModel?.contributingFactors ?? [], id: \.name) { factor in
                    FactorProgressBar(factor: factor)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(Typography.headline)

            VStack(spacing: 12) {
                ForEach(viewModel?.recommendations ?? [], id: \.title) { rec in
                    RecommendationCard(recommendation: rec)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    private var category: StressCategory {
        switch measurement.stressLevel {
        case 0...25: return .relaxed
        case 26...50: return .mild
        case 51...75: return .moderate
        default: return .high
        }
    }

    private var todayAvgText: String {
        guard let viewModel = viewModel, let avg = viewModel.todayAverage else { return "--" }
        return "\(Int(avg)) ms"
    }

    private var weeklyAvgText: String {
        guard let viewModel = viewModel, let avg = viewModel.weeklyAverage else { return "--" }
        return "\(Int(avg)) ms"
    }

    private var baselineRangeText: String {
        guard let viewModel = viewModel, let baseline = viewModel.baseline else { return "--" }
        let lowerBound = baseline.baselineHRV - 10
        let upperBound = baseline.baselineHRV + 10
        return "\(Int(lowerBound))-\(Int(upperBound)) ms"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, YYYY"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct HRVRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 32)

            Text(label)
                .font(Typography.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(Typography.body)
                .fontWeight(.medium)
        }
    }
}

func trendText(_ trend: TrendDirection) -> String {
    switch trend {
    case .up: return "Above average"
    case .down: return "Below average"
    case .stable: return "Stable"
    }
}
