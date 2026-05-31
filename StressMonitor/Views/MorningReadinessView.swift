import SwiftUI
import Charts

/// Morning Readiness card — WHOOP/Oura-inspired readiness assessment.
/// Shows a circular readiness score, 7-day HRV trend sparkline, and actionable insights.
struct MorningReadinessView: View {
    @ObservedObject var readinessService: MorningReadinessService

    @State private var animatedScore: Double = 0
    @State private var showDetails = false

    // MARK: - Constants

    private let gaugeSize: CGFloat = 140
    private let lineWidth: CGFloat = 14

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            header

            // Main content
            HStack(alignment: .top, spacing: 20) {
                // Circular gauge
                readinessGauge

                // Score details + trend
                VStack(alignment: .leading, spacing: 12) {
                    scoreSummary
                    trendSparkline
                }
            }

            // Insights
            if !readinessService.insights.isEmpty {
                insightsSection
            }

            // Advice
            adviceSection
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedScore = readinessService.readinessScore ?? 0
            }
        }
        .onChange(of: readinessService.readinessScore) { _, newScore in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedScore = newScore ?? 0
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Label("Morning Readiness", systemImage: "sunrise.fill")
                    .font(.headline)
                    .foregroundColor(.orange)

                if let computed = readinessService.lastComputed {
                    Text("Updated \(computed, style: .relative) ago")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Level badge
            Text(readinessService.readinessLevel.emoji)
                .font(.title3)

            Text(readinessService.readinessLevel.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(levelColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(levelColor.opacity(0.15))
                .cornerRadius(8)
        }
    }

    // MARK: - Readiness Gauge

    private var readinessGauge: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    Color.gray.opacity(0.12),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: gaugeSize, height: gaugeSize)

            // Progress arc
            Circle()
                .trim(from: 0, to: animatedScore / 100.0)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gaugeColors),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * (animatedScore / 100.0))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: gaugeSize, height: gaugeSize)
                .rotationEffect(.degrees(-90))

            // Center text
            VStack(spacing: 2) {
                if readinessService.readinessScore != nil {
                    Text(scoreText)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(levelColor)
                        .contentTransition(.numericText())
                } else {
                    Text("—")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Text("readiness")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Score Summary

    private var scoreSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let morningHRV = readinessService.morningHRV {
                HStack(spacing: 4) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(String(format: "Morning HRV: %.0f ms", morningHRV))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                HStack(spacing: 4) {
                    Image(systemName: "chart.line.flattrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(.purple)
                    Text(String(format: "7-day avg: %.0f ms", readinessService.baselineHRV))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Deviation indicator
                let deviation = ((morningHRV - readinessService.baselineHRV) / readinessService.baselineHRV) * 100
                HStack(spacing: 4) {
                    Image(systemName: deviation >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                        .foregroundColor(deviation >= 0 ? .green : .red)
                    Text(String(format: "%@%.0f%% vs baseline", deviation >= 0 ? "+" : "", deviation))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(deviation >= 0 ? .green : .red)
                }
            } else {
                Text("No morning HRV data yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Trend Sparkline

    private var trendSparkline: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("7-Day Trend")
                .font(.caption2)
                .foregroundColor(.secondary)

            if readinessService.hrvTrend.count >= 2 {
                Chart(readinessService.hrvTrend) { point in
                    LineMark(
                        x: .value("Day", point.date),
                        y: .value("HRV", point.hrv)
                    )
                    .foregroundStyle(point.isToday ? Color.orange.gradient : Color.blue.gradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Day", point.date),
                        yStart: .value("Min", readinessService.hrvTrend.map(\.hrv).min().map { $0 * 0.8 } ?? 0),
                        yEnd: .value("HRV", point.hrv)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .blue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    // Today dot
                    if point.isToday {
                        PointMark(
                            x: .value("Day", point.date),
                            y: .value("HRV", point.hrv)
                        )
                        .foregroundStyle(.orange)
                        .symbolSize(60)
                    }

                    // Baseline rule
                    RuleMark(y: .value("Baseline", readinessService.baselineHRV))
                        .foregroundStyle(.purple.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { value in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 60)
            } else {
                // Not enough data for sparkline
                HStack {
                    Spacer()
                    Text("Need 2+ days of data")
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                    Spacer()
                }
                .frame(height: 60)
            }
        }
    }

    // MARK: - Insights

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            ForEach(readinessService.insights) { insight in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: insight.icon)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(insight.detail)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Advice

    private var adviceSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)

            Text(readinessService.readinessLevel.advice)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(Color.yellow.opacity(0.08))
        .cornerRadius(10)
    }

    // MARK: - Helpers

    private var scoreText: String {
        String(format: "%.0f", animatedScore)
    }

    private var levelColor: Color {
        switch readinessService.readinessLevel {
        case .noData:    return .secondary
        case .low:       return .red
        case .moderate:  return .orange
        case .good:      return .green
        case .excellent: return .mint
        }
    }

    private var gaugeColors: [Color] {
        switch readinessService.readinessLevel {
        case .noData:    return [.gray, .gray]
        case .low:       return [.red, .orange]
        case .moderate:  return [.orange, .yellow]
        case .good:      return [.green, .mint]
        case .excellent: return [.mint, .green]
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Good readiness
            MorningReadinessView(readinessService: {
                let svc = MorningReadinessService()
                svc.readinessScore = 72
                svc.readinessLevel = .good
                svc.morningHRV = 68
                svc.baselineHRV = 58
                svc.lastComputed = Date()
                svc.hrvTrend = [
                    .init(date: Date().addingTimeInterval(-86400 * 6), hrv: 52, isToday: false),
                    .init(date: Date().addingTimeInterval(-86400 * 5), hrv: 55, isToday: false),
                    .init(date: Date().addingTimeInterval(-86400 * 4), hrv: 48, isToday: false),
                    .init(date: Date().addingTimeInterval(-86400 * 3), hrv: 60, isToday: false),
                    .init(date: Date().addingTimeInterval(-86400 * 2), hrv: 58, isToday: false),
                    .init(date: Date().addingTimeInterval(-86400 * 1), hrv: 62, isToday: false),
                    .init(date: Date(), hrv: 68, isToday: true),
                ]
                svc.insights = [
                    .init(icon: "arrow.up.circle.fill", title: "Above Baseline", detail: "Your morning HRV is 17% above your 7-day average (68 vs 58 ms)."),
                    .init(icon: "chart.line.uptrend.xyaxis", title: "Upward Trend", detail: "Your morning HRV has been trending up — recovery is improving."),
                ]
                return svc
            }())

            // No data
            MorningReadinessView(readinessService: {
                let svc = MorningReadinessService()
                svc.readinessScore = nil
                svc.readinessLevel = .noData
                svc.baselineHRV = 60
                return svc
            }())

            // Low readiness
            MorningReadinessView(readinessService: {
                let svc = MorningReadinessService()
                svc.readinessScore = 18
                svc.readinessLevel = .low
                svc.morningHRV = 32
                svc.baselineHRV = 55
                svc.lastComputed = Date()
                svc.hrvTrend = [
                    .init(date: Date().addingTimeInterval(-86400 * 3), hrv: 55, isToday: false),
                    .init(date: Date().addingTimeInterval(-86400 * 2), hrv: 45, isToday: false),
                    .init(date: Date().addingTimeInterval(-86400 * 1), hrv: 38, isToday: false),
                    .init(date: Date(), hrv: 32, isToday: true),
                ]
                svc.insights = [
                    .init(icon: "arrow.down.circle.fill", title: "Below Baseline", detail: "Your morning HRV is 42% below your 7-day average."),
                    .init(icon: "chart.line.downtrend.xyaxis", title: "Downward Trend", detail: "Your morning HRV has been declining. Consider reducing training load."),
                ]
                return svc
            }())
        }
        .padding()
    }
}
