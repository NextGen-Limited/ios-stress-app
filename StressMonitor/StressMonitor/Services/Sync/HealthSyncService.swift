import Combine
import Foundation

/// Orchestrates the daily aggregate upload: once per local day, on
/// foreground, only after server-side consent. The server is the consent
/// authority — a 403 CONSENT_REQUIRED sets `needsConsent` and the app
/// surfaces the prompt instead of retrying silently.
///
/// Both external edges are injectable closures (aggregation + network) so
/// tests drive the state machine without HealthKit or network; the
/// defaults wire the real `HealthKitManager` / `StressAPIClient` paths.
/// No measurement value is ever logged.
@MainActor
final class HealthSyncService: ObservableObject {
    static let shared = HealthSyncService()

    @Published private(set) var needsConsent = false
    @Published private(set) var lastSyncFailed = false

    private let defaults: UserDefaults
    private let upload: (DailySummaryPayload) async throws -> ServerStressScore
    private let aggregates: (Date) async throws -> HealthKitManager.DailyAggregates
    private let calendar: Calendar
    private let dayKey = "health.lastUploadedLocalDate"

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        aggregates: @escaping (Date) async throws -> HealthKitManager.DailyAggregates = {
            try await HealthKitManager().dailyAggregates(for: $0)
        },
        upload: @escaping (DailySummaryPayload) async throws -> ServerStressScore = {
            try await StressAPIClient().uploadDailySummary($0)
        }
    ) {
        self.defaults = defaults
        self.upload = upload
        self.aggregates = aggregates
        self.calendar = calendar
    }

    var lastUploadedDayKey: String? {
        defaults.string(forKey: dayKey)
    }

    /// Yesterday is the last fully-elapsed local day — upload it once.
    func syncYesterdayIfNeeded() async {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let key = formatter.string(from: yesterday)
        guard lastUploadedDayKey != key else { return }

        do {
            let daily = try await aggregates(yesterday)
            guard let payload = HealthKitManager.makePayload(
                aggregates: daily, date: yesterday, timeZone: .current) else {
                defaults.set(key, forKey: dayKey) // nothing measured — done for today
                return
            }
            _ = try await upload(payload)
            defaults.set(key, forKey: dayKey)
            needsConsent = false
            lastSyncFailed = false
        } catch HealthAPIError.consentRequired {
            needsConsent = true
        } catch {
            lastSyncFailed = true // retried next foreground
        }
    }

    func markConsentGranted() {
        needsConsent = false
    }
}
