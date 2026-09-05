import SwiftUI

/// Server-computed daily stress score (GET /stress/scores) shown on the
/// dashboard right below the local on-device reading. Fetches once per
/// appearance and renders the newest row only; stays graceful while the
/// endpoint is empty or unreachable.
struct ServerScoreCard: View {
    @State private var score: ServerStressScore?
    @State private var failed = false
    @State private var loading = true

    private var levelColor: Color {
        switch score?.level {
        case "low": return .green
        case "moderate": return .orange
        case "high": return .red
        default: return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Coach Score")
                    .font(.headline)
                Spacer()
                if loading { ProgressView() }
            }
            if let score {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(score.score)")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(levelColor)
                    VStack(alignment: .leading) {
                        Text(score.level.capitalized)
                            .font(.title3)
                            .foregroundStyle(levelColor)
                        Text(score.localDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if !score.factors.isEmpty {
                    ForEach(score.factors, id: \.self) { factor in
                        Label(factor, systemImage: "circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if failed {
                Text("Server score unavailable.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if !loading {
                Text("No server score yet — sync starts after you allow health data.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.Wellness.adaptiveCardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .task {
            do {
                score = try await StressAPIClient().fetchStressScores().first
            } catch {
                failed = true
            }
            loading = false
        }
    }
}
