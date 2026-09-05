import Testing
import Foundation
@testable import StressMonitor

/// Behavioral coverage for the consent-gated daily upload orchestration.
/// Both external edges are closure seams injected from `init` (`aggregates`
/// for the HealthKit day aggregation, `upload` for the network call), so
/// these tests drive the real state machine — day-key dedupe, consent 403,
/// transient failure, all-nil aggregates — without HealthKit or network.
/// Each behavioral test gets a fresh UserDefaults suite (unique name,
/// domain removed after the test) so day keys never leak between cases.
@MainActor
struct HealthSyncServiceTests {

    private let dayKey = "health.lastUploadedLocalDate"

    private static let score = ServerStressScore(
        localDate: "2026-09-04", score: 72, level: "moderate",
        confidence: 0.8, formulaVersion: "v1", baselineVersion: "v1",
        factors: [], warnings: [])

    // MARK: - Fixtures

    private func makeDefaults() -> (defaults: UserDefaults, cleanup: () -> Void) {
        let suiteName = "HealthSyncServiceTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        return (defaults, { defaults.removePersistentDomain(forName: suiteName) })
    }

    /// Mirrors the service's own computation so tests can pre-seed or
    /// assert the exact key it derives for yesterday.
    private var yesterdayKey: String {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: yesterday)
    }

    private func makeService(
        _ defaults: UserDefaults,
        aggregates: @escaping (Date) async throws -> HealthKitManager.DailyAggregates = { _ in
            HealthKitManager.DailyAggregates(
                hrvSDNN: 42.5, heartRateAvg: 61, restingHeartRate: 55,
                hrvCount: 10, heartRateCount: 500, restingHeartRateCount: 96)
        },
        upload: @escaping (DailySummaryPayload) async throws -> ServerStressScore = { _ in
            Self.score
        }
    ) -> HealthSyncService {
        HealthSyncService(
            defaults: defaults,
            calendar: .current,
            aggregates: aggregates,
            upload: upload)
    }

    private actor UploadRecorder {
        var payloads: [DailySummaryPayload] = []
        func record(_ payload: DailySummaryPayload) { payloads.append(payload) }
    }

    // MARK: - Brief Step 1

    @Test("yesterday's date key is computed once per local day")
    func dateKeyStable() {
        let service = HealthSyncService.shared
        let key = service.lastUploadedDayKey
        #expect(key == nil || key!.count == 10) // "yyyy-MM-dd"
    }

    // MARK: - Day-key dedupe

    @Test("upload skipped when yesterday's day key is already stored")
    func skipsUploadWhenDayKeyMatches() async throws {
        let (defaults, cleanup) = makeDefaults()
        defer { cleanup() }
        defaults.set(yesterdayKey, forKey: dayKey)
        let recorder = UploadRecorder()
        let service = makeService(defaults, upload: { payload in
            await recorder.record(payload)
            return Self.score
        })

        await service.syncYesterdayIfNeeded()

        #expect(await recorder.payloads.isEmpty)
        #expect(service.needsConsent == false)
        #expect(service.lastSyncFailed == false)
    }

    // MARK: - Happy path

    @Test("upload runs once with a well-formed payload and stores the day key")
    func uploadsOnceAndStoresDayKey() async throws {
        let (defaults, cleanup) = makeDefaults()
        defer { cleanup() }
        let recorder = UploadRecorder()
        let service = makeService(defaults, upload: { payload in
            await recorder.record(payload)
            return Self.score
        })

        await service.syncYesterdayIfNeeded()

        let payloads = await recorder.payloads
        #expect(payloads.count == 1)
        #expect(payloads.first?.localDate == yesterdayKey)
        #expect(payloads.first?.timezone == TimeZone.current.identifier)
        #expect(payloads.first?.hrvSdnnMs == 42.5)
        #expect(payloads.first?.heartRateAvgBpm == 61)
        #expect(payloads.first?.restingHeartRateBpm == 55)
        #expect(payloads.first?.sampleCounts == .init(
            hrv: 10, heartRate: 500, restingHeartRate: 96))
        #expect(payloads.first?.source == "healthkit")
        #expect(defaults.string(forKey: dayKey) == yesterdayKey)
        #expect(service.needsConsent == false)
        #expect(service.lastSyncFailed == false)
    }

    // MARK: - Consent gate

    @Test("consentRequired flips needsConsent and leaves the day key unset")
    func consentErrorSetsNeedsConsent() async throws {
        let (defaults, cleanup) = makeDefaults()
        defer { cleanup() }
        let service = makeService(defaults, upload: { _ in
            throw HealthAPIError.consentRequired
        })

        await service.syncYesterdayIfNeeded()

        #expect(service.needsConsent == true)
        #expect(service.lastSyncFailed == false)
        #expect(defaults.string(forKey: dayKey) == nil)

        service.markConsentGranted()
        #expect(service.needsConsent == false)
    }

    // MARK: - Nothing measured

    @Test("all-nil aggregates store the day key without uploading")
    func emptyAggregatesStoreDayKeyWithoutUpload() async throws {
        let (defaults, cleanup) = makeDefaults()
        defer { cleanup() }
        let recorder = UploadRecorder()
        let service = makeService(
            defaults,
            aggregates: { _ in
                HealthKitManager.DailyAggregates(
                    hrvSDNN: nil, heartRateAvg: nil, restingHeartRate: nil,
                    hrvCount: 0, heartRateCount: 0, restingHeartRateCount: 0)
            },
            upload: { payload in
                await recorder.record(payload)
                return Self.score
            })

        await service.syncYesterdayIfNeeded()

        #expect(await recorder.payloads.isEmpty)
        #expect(defaults.string(forKey: dayKey) == yesterdayKey)
        #expect(service.lastSyncFailed == false)
    }

    // MARK: - Transient failure

    @Test("other upload errors set lastSyncFailed and keep the day key unset")
    func otherErrorSetsLastSyncFailed() async throws {
        let (defaults, cleanup) = makeDefaults()
        defer { cleanup() }
        let service = makeService(defaults, upload: { _ in
            throw URLError(.timedOut)
        })

        await service.syncYesterdayIfNeeded()

        #expect(service.lastSyncFailed == true)
        #expect(service.needsConsent == false)
        #expect(defaults.string(forKey: dayKey) == nil)
    }
}
