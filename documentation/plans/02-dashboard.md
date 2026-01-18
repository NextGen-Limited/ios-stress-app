# Dashboard

> **Created by:** Phuong Doan
> **Feature:** Main app dashboard showing current stress status
> **Designs Referenced:** 3 screens
> - `dashboard_dark_mode`
> - `stress_dashboard_today_1`
> - `stress_dashboard_today_2`

---

## Overview

The dashboard is the main screen users see when opening the app. It displays:
- Current stress score with animated ring
- Quick metrics (HRV, Resting HR)
- Weekly summary
- Measure now CTA

---

## 1. Main Dashboard View

**Design:** `dashboard_dark_mode`, `stress_dashboard_today_1`

```swift
// StressMonitor/Views/DashboardView.swift

import SwiftUI
import Observation

@Observable
class DashboardViewModel {
    var currentStress: StressResult?
    var currentHRV: Double?
    var restingHR: Double?
    var hrvTrend: MetricTrend?
    var hrTrend: MetricTrend?
    var hrvHistory: [Double] = []
    var userName: String = "Alex"
    var currentDate: String = "Monday, Oct 24"
    var weeklyAverage: Double = 45
    var weeklyComparisonText: String = "You are 15% more relaxed"

    private let healthKit: HealthKitServiceProtocol
    private let repository: StressRepositoryProtocol

    init(
        healthKit: HealthKitServiceProtocol = DefaultHealthKitService(),
        repository: StressRepositoryProtocol = StressRepository()
    ) {
        self.healthKit = healthKit
        self.repository = repository
    }

    func loadDashboardData() async {
        // Fetch latest stress measurement
        if let latest = try? await repository.fetchRecent(limit: 1).first {
            currentStress = latest
            currentHRV = latest.hrv
            restingHR = latest.heartRate
        }

        // Fetch HRV history for charts
        let history = try? await repository.fetchRecent(limit: 7)
        hrvHistory = history?.map(\.hrv) ?? []

        // Calculate trends
        hrvTrend = calculateHRVTrend()
        hrTrend = calculateHRTrend()

        // Load user info
        loadUserInfo()
    }

    func triggerMeasurement() {
        // Navigate to measurement flow
    }

    private func calculateHRVTrend() -> MetricTrend {
        guard hrvHistory.count >= 2 else { return nil }
        let previous = hrvHistory[hrvHistory.count - 2]
        let current = hrvHistory.last ?? 0
        let diff = current - previous

        if diff > 5 {
            return .up(value: "+\(Int(diff))ms", isGood: true)
        } else if diff < -5 {
            return .down(value: "\(Int(diff))ms", isGood: false)
        }
        return .neutral
    }

    private func calculateHRTrend() -> MetricTrend {
        // Similar calculation for heart rate
        return .down(value: "-2 bpm", isGood: true)
    }

    private func loadUserInfo() {
        // Load user profile data
    }
}

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ZStack {
            // Background gradient effects
            backgroundEffects
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    header

                    // Stress ring card
                    stressRingCard

                    // Quick metrics grid
                    metricsGrid

                    // Weekly summary
                    weeklySummaryCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 104) // Header space
                .padding(.bottom, 100) // Tab bar space
            }
        }
        .background(Color.backgroundDark)
        .task {
            await viewModel.loadDashboardData()
        }
    }

    private var backgroundEffects: some View {
        VStack {
            LinearGradient(
                colors: [Color.primary.opacity(0.1), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 256)
            Spacer()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.currentDate.uppercased())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)

                Text("Good Evening, \(viewModel.userName)")
                    .font(.system(size: 24, weight: .bold))
            }

            Spacer()

            Button(action: { /* Profile */ }) {
                AsyncImage(url: URL(string: userProfileImageURL)) { image in
                    image.resizable()
                } placeholder: {
                    Circle()
                        .fill(Color.cardDark)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Color.backgroundDark.opacity(0.8),
            in: Rectangle()
        )
        .backdropBlur()
    }

    private var stressRingCard: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Stress Score")
                    .font(.system(size: 12, weight: .semibold))
                    .uppercaseSmallCaps()
                    .foregroundColor(.textSecondary)

                Spacer()

                Button(action: { /* Info */ }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.primary)
                }
            }

            StressRingView(
                stressLevel: viewModel.currentStress?.level ?? 0,
                category: viewModel.currentStress?.category ?? .moderate,
                confidence: viewModel.currentStress?.confidence
            )

            Button(action: { viewModel.triggerMeasurement() }) {
                HStack(spacing: 8) {
                    Image(systemName: "vital_signs")
                    Text("Measure Now")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.primary)
                .cornerRadius(28)
                .shadow(color: Color.primary.opacity(0.2), radius: 12, y: 6)
            }
        }
        .cardPadding(.spacious)
        .background(Color.cardDark)
        .cornerRadius(16)
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "HRV",
                value: "\(Int(viewModel.currentHRV ?? 0))",
                subtitle: "ms",
                icon: "waveform.path",
                iconColor: .successGreen,
                trend: viewModel.hrvTrend,
                chartData: viewModel.hrvHistory
            )

            MetricCard(
                title: "Resting HR",
                value: "\(Int(viewModel.restingHR ?? 0))",
                subtitle: "bpm",
                icon: "heart.fill",
                iconColor: .healthRed,
                trend: viewModel.hrTrend,
                chartData: nil
            )
        }
    }

    private var weeklySummaryCard: some View {
        Button(action: { /* Navigate to trends */ }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                    Image(systemName: "calendar")
                        .foregroundColor(.white)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Average")
                        .font(.system(size: 17, weight: .semibold))
                    Text(viewModel.weeklyComparisonText)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .cardPadding(.regular)
        }
        .background(Color.cardDark)
        .cornerRadius(16)
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
```

---

## 2. Dashboard Header Component

```swift
// StressMonitor/Views/Components/DashboardHeader.swift

import SwiftUI

struct DashboardHeader: View {
    let userName: String
    let currentDate: String
    var onProfileTap: (() -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(currentDate.uppercased())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)

                Text("Good Evening, \(userName)")
                    .font(.system(size: 24, weight: .bold))
            }

            Spacer()

            Button(action: { onProfileTap?() }) {
                AsyncImage(url: URL(string: userProfileImageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                    case .failure(_):
                        Circle()
                            .fill(Color.cardDark)
                            .overlay {
                                Text(String(userName.prefix(1)))
                                    .foregroundColor(.textSecondary)
                            }
                    default:
                        Circle()
                            .fill(Color.cardDark)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Color.backgroundDark.opacity(0.8),
            in: Rectangle()
        )
        .backdropBlur()
    }
}

#Preview {
    DashboardHeader(
        userName: "Alex",
        currentDate: "Monday, Oct 24"
    )
    .background(Color.backgroundDark)
}
```

---

## 3. Weekly Summary Card

```swift
// StressMonitor/Views/Components/WeeklySummaryCard.swift

import SwiftUI

struct WeeklySummaryCard: View {
    let averageStress: Double
    let comparisonText: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .frame(width: 48, height: 48)

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Average")
                        .font(.system(size: 17, weight: .semibold))

                    Text(comparisonText)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .cardPadding(.regular)
        }
        .buttonStyle(.plain)
        .background(Color.cardDark)
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly average: \(comparisonText)")
    }
}

#Preview {
    WeeklySummaryCard(
        averageStress: 45,
        comparisonText: "You are 15% more relaxed"
    ) {
        print("Tapped")
    }
    .padding()
    .background(Color.backgroundDark)
}
```

---

## 4. AI Insight Card

**Design:** `stress_dashboard_today_2` (AI Insight section)

```swift
// StressMonitor/Views/Components/AIInsightCard.swift

import SwiftUI

struct AIInsightCard: View {
    let insight: String
    let chartData: [Double]
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.primary)
                        Text("AI Insight")
                            .font(.system(size: 15, weight: .bold))
                    }

                    Spacer()

                    Text("New")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                // Insight text
                Text(insight)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)

                // Mini chart
                InsightSparkline(data: chartData)
                    .frame(height: 64)
            }
            .cardPadding(.regular)
        }
        .buttonStyle(.plain)
        .background(Color.cardDark)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AI insight: \(insight)")
    }
}

struct InsightSparkline: View {
    let data: [Double]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let step = width / CGFloat(max(data.count - 1, 1))

            let min = data.min() ?? 0
            let max = data.max() ?? 100
            let range = max - min

            func y(for value: Double) -> CGFloat {
                if range == 0 { return height / 2 }
                return height - CGFloat((value - min) / range) * height * 0.7 - height * 0.15
            }

            ZStack {
                // Grid lines
                ForEach(0..<3) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                }

                // Area fill
                Path { path in
                    guard !data.isEmpty else { return }
                    path.move(to: CGPoint(x: 0, y: height))

                    for (index, value) in data.enumerated() {
                        path.addLine(to: CGPoint(x: CGFloat(index) * step, y: y(for: value)))
                    }

                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.primary.opacity(0.2), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line stroke
                Path { path in
                    guard !data.isEmpty else { return }
                    path.move(to: CGPoint(x: 0, y: y(for: data[0])))

                    for (index, value) in data.enumerated() {
                        path.addLine(to: CGPoint(x: CGFloat(index) * step, y: y(for: value)))
                    }
                }
                .stroke(Color.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }
        }
    }
}

#Preview {
    AIInsightCard(
        insight: "Your recovery is slightly lower than usual. Consider a 5-minute breathing exercise to reset your nervous system.",
        chartData: [45, 52, 48, 55, 50, 58, 52]
    )
    .padding()
    .background(Color.backgroundDark)
}
```

---

## 5. Measure Now Button

```swift
// StressMonitor/Views/Components/MeasureNowButton.swift

import SwiftUI

struct MeasureNowButton: View {
    var onTap: () -> Void
    var isLoading: Bool = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "vital_signs")
                    Text("Measure Now")
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if isLoading {
                        Color.primary.opacity(0.7)
                    } else {
                        Color.primary
                    }
                }
            )
            .cornerRadius(28)
            .shadow(color: Color.primary.opacity(0.3), radius: 12, y: 6)
        }
        .disabled(isLoading)
        .accessibilityLabel("Measure stress now")
        .accessibilityHint("Start a new stress measurement")
    }
}

#Preview("Normal") {
    MeasureNowButton {
        print("Measure tapped")
    }
    .padding()
    .background(Color.backgroundDark)
}

#Preview("Loading") {
    MeasureNowButton(isLoading: true) { }
    .padding()
    .background(Color.backgroundDark)
}
```

---

## 6. Dashboard State Handling

```swift
// StressMonitor/Views/Components/DashboardStateView.swift

import SwiftUI

enum DashboardState {
    case loading
    case empty
    case populated(DashboardData)
    case error(String)

    struct DashboardData {
        let currentStress: StressResult
        let hrvHistory: [Double]
        let weeklyAverage: Double
    }
}

struct DashboardStateView: View {
    let state: DashboardState
    var onRetry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            loadingView
        case .empty:
            emptyStateView
        case .populated:
            // Main dashboard content
            EmptyView()
        case .error(let message):
            errorView(message)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                .scaleEffect(1.5)

            Text("Loading your stress data...")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .frame(maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundColor(.primary.opacity(0.5))

            Text("No Measurements Yet")
                .font(.title2)
                .foregroundColor(.textMain)

            Text("Take your first measurement to see your stress data here.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            MeasureNowButton {
                onRetry()
            }
            .padding(.horizontal, 24)
        }
        .frame(maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.stressHigh)

            Text("Unable to load data")
                .font(.title2)
                .foregroundColor(.textMain)

            Text(message)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onRetry) {
                Text("Try Again")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 24)
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview("Loading") {
    DashboardStateView(state: .loading) { }
        .background(Color.backgroundDark)
}

#Preview("Empty") {
    DashboardStateView(state: .empty) { }
        .background(Color.backgroundDark)
}

#Preview("Error") {
    DashboardStateView(state: .error("Connection failed")) { }
        .background(Color.backgroundDark)
}
```

---

## 7. Pull to Refresh

```swift
// StressMonitor/Views/Components/DashboardRefreshView.swift

import SwiftUI

struct RefreshableDashboard: View {
    @State private var isRefreshing = false
    let onRefresh: () async -> Void
    let content: () -> any View

    var body: some View {
        List {
            content()
        }
        .listStyle(.plain)
        .refreshable {
            isRefreshing = true
            await onRefresh()
            isRefreshing = false
        }
    }
}
```

---

## File Structure

```
StressMonitor/Views/Dashboard/
├── DashboardView.swift
├── Components/
│   ├── DashboardHeader.swift
│   ├── WeeklySummaryCard.swift
│   ├── AIInsightCard.swift
│   ├── MeasureNowButton.swift
│   ├── DashboardStateView.swift
│   └── DashboardRefreshView.swift
└── ViewModels/
    └── DashboardViewModel.swift
```

---

## Dependencies

- **Design System:** Colors, components from `00-design-system-components.md`
- **Data Models:** `StressMeasurement`, `StressCategory`
- **HealthKit:** For fetching HRV and heart rate data
- **Repository:** For accessing stored measurements

---

## User Flow

1. User opens app → Dashboard loads
2. Shows current stress level with ring
3. Displays quick metrics (HRV, HR)
4. User taps "Measure Now" → Triggers measurement flow
5. User taps weekly summary → Navigates to History/Trends
6. Pull to refresh → Reloads latest data
