import Foundation
import SwiftData
import Testing
@testable import StressMonitor

/// Test double for ``ServerSessionWiping`` that drives the factory-reset
/// wipe loop without any network access (derived-SES-03). Records every
/// call in order so tests can pin the exact list → delete → list sequence.
@MainActor
final class FakeServerSessionWiper: ServerSessionWiping, @unchecked Sendable {
    enum Behavior {
        /// Serves the scripted pages in call order; beyond the script every
        /// list returns an empty page (loop terminates).
        case pages([[ChatSession]])
        /// Ignores the offset and always returns the same page — a
        /// misbehaving server that never runs out of rows (safety-cap test).
        case always([ChatSession])
        /// Throws from the first list call (auth-unavailable / network).
        case throwOnList(Error)
    }

    private(set) var calls: [String] = []
    private(set) var listCallCount = 0
    var behavior: Behavior

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func listSessions(limit: Int, offset: Int) async throws -> [ChatSession] {
        calls.append("list(limit:\(limit), offset:\(offset))")
        listCallCount += 1
        switch behavior {
        case .pages(let pages):
            let index = listCallCount - 1
            return index < pages.count ? pages[index] : []
        case .always(let page):
            return page
        case .throwOnList(let error):
            throw error
        }
    }

    func deleteSession(id: UUID) async throws {
        calls.append("delete(\(id.uuidString))")
    }
}

/// CloudKit double that records whether the factory reset ever reached the
/// CloudKit phase — the wipe runs before it, so a Phase-0 abort must leave
/// this counter at zero.
@MainActor
final class RecordingCloudKitResetService: CloudKitResetServiceProtocol, @unchecked Sendable {
    private(set) var databaseResetCallCount = 0

    func deleteRecords(ofType recordType: CloudKitRecordType, expectedProgress: ClosedRange<Double>) async throws {}

    func deleteRecords(ofType recordType: CloudKitRecordType, in range: ClosedRange<Date>) async throws {}

    func deleteRecords(ofType recordType: CloudKitRecordType, before date: Date) async throws {}

    func deleteAllRecords(confirmation: (() async -> Bool)?, includeBaseline: Bool) async throws {}

    func performDatabaseReset(confirmation: (() async -> Bool)?) async throws {
        databaseResetCallCount += 1
    }
}

/// Factory reset wipes the user's server chat sessions (paginated
/// GET /sessions → DELETE /sessions?id= per row) as the FIRST phase, before
/// the local wipe, while authentication is still live — and clears the
/// stored chat session id on every successful path.
@Suite("Data Deleter Server Session Wipe")
@MainActor
struct DataDeleterServerWipeTests {

    private static let sessionA = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private static let sessionB = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private static let sessionC = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

    // MARK: - Fixtures

    private func makeSession(_ id: UUID) -> ChatSession {
        ChatSession(id: id, title: "Session", createdAt: nil, updatedAt: nil)
    }

    /// In-memory context mirroring the consolidation tests' setup, plus
    /// CharacterUnlock (performFactoryReset deletes that model too).
    private func makeContextWithOneMeasurement() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: StressMeasurement.self, CharacterUnlock.self,
            configurations: config
        )
        let ctx = container.mainContext
        ctx.insert(StressMeasurement(timestamp: Date(), stressLevel: 50, hrv: 40, restingHeartRate: 65))
        try ctx.save()
        return ctx
    }

    private func makeService(
        _ ctx: ModelContext,
        cloudKit: RecordingCloudKitResetService,
        wiper: FakeServerSessionWiper
    ) -> DataDeleterService {
        DataDeleterService(
            modelContext: ctx,
            cloudKitResetService: cloudKit,
            repository: StressRepository(modelContext: ctx),
            serverSessionWiper: wiper,
            logger: .default
        )
    }

    private func seedStoredChatSessionId() {
        UserDefaults.standard.set("seed-session-id", forKey: "stressChatSessionId")
    }

    // MARK: - Ordered pagination wipe

    @Test("factory reset lists, deletes per row, and pages to exhaustion before the local wipe")
    func factoryResetWipesEveryServerSessionPageByPage() async throws {
        let ctx = try makeContextWithOneMeasurement()
        let cloudKit = RecordingCloudKitResetService()
        let wiper = FakeServerSessionWiper(behavior: .pages([
            [makeSession(Self.sessionA), makeSession(Self.sessionB)],
            [makeSession(Self.sessionC)],
        ]))
        seedStoredChatSessionId()
        let service = makeService(ctx, cloudKit: cloudKit, wiper: wiper)

        try await service.performFactoryReset()

        #expect(wiper.calls == [
            "list(limit:20, offset:0)",
            "delete(\(Self.sessionA.uuidString))",
            "delete(\(Self.sessionB.uuidString))",
            "list(limit:20, offset:2)",
            "delete(\(Self.sessionC.uuidString))",
            "list(limit:20, offset:3)",
        ])
        #expect(cloudKit.databaseResetCallCount == 1)

        let remaining = try ctx.fetch(FetchDescriptor<StressMeasurement>())
        #expect(remaining.isEmpty)

        #expect(UserDefaults.standard.string(forKey: "stressChatSessionId") == nil)
    }

    // MARK: - Safety cap

    @Test("a server that never runs out of rows terminates at the page cap and fails the reset")
    func runawayWipeLoopTerminatesAtPageCapAndFailsReset() async throws {
        let ctx = try makeContextWithOneMeasurement()
        let cloudKit = RecordingCloudKitResetService()
        let wiper = FakeServerSessionWiper(behavior: .always([makeSession(Self.sessionA)]))
        let service = makeService(ctx, cloudKit: cloudKit, wiper: wiper)

        do {
            try await service.performFactoryReset()
            Issue.record("Expected factory reset to throw at the wipe page cap")
        } catch let DeletionError.serverSessionError(underlying) {
            #expect(underlying is URLError)
        } catch {
            Issue.record("Expected DeletionError.serverSessionError, got \(error)")
        }

        // Bounded iterations: the loop must stop at the 50-page cap, not hang.
        #expect(wiper.listCallCount == 50)

        // The reset failed loudly BEFORE any local deletion happened.
        let remaining = try ctx.fetch(FetchDescriptor<StressMeasurement>())
        #expect(remaining.count == 1)
        #expect(cloudKit.databaseResetCallCount == 0)
    }

    // MARK: - Auth-unavailable skip (Q2)

    @Test("no authenticated identity (signed out) skips the wipe, logs, and still resets locally")
    func signedOutSkipsServerWipeAndStillCompletesReset() async throws {
        let ctx = try makeContextWithOneMeasurement()
        let cloudKit = RecordingCloudKitResetService()
        let wiper = FakeServerSessionWiper(
            behavior: .throwOnList(LLMServiceError.unavailable(reason: "Please sign in to use AI Chat."))
        )
        seedStoredChatSessionId()
        let service = makeService(ctx, cloudKit: cloudKit, wiper: wiper)

        try await service.performFactoryReset()

        // Skip happened before any delete was issued.
        #expect(wiper.calls == ["list(limit:20, offset:0)"])

        // The reset still ran to completion: CloudKit + local wipe happened.
        #expect(cloudKit.databaseResetCallCount == 1)
        let remaining = try ctx.fetch(FetchDescriptor<StressMeasurement>())
        #expect(remaining.isEmpty)

        #expect(UserDefaults.standard.string(forKey: "stressChatSessionId") == nil)
    }

    @Test("a 401 from the sessions endpoint also skips the wipe (stale token, no identity)")
    func unauthorizedSkipsServerWipeAndStillCompletesReset() async throws {
        let ctx = try makeContextWithOneMeasurement()
        let cloudKit = RecordingCloudKitResetService()
        let wiper = FakeServerSessionWiper(behavior: .throwOnList(SessionsAPIError.unauthorized))
        let service = makeService(ctx, cloudKit: cloudKit, wiper: wiper)

        try await service.performFactoryReset()

        #expect(wiper.calls == ["list(limit:20, offset:0)"])
        let remaining = try ctx.fetch(FetchDescriptor<StressMeasurement>())
        #expect(remaining.isEmpty)
    }

    // MARK: - Fail loudly on server/network errors (Q2)

    @Test("a network error fails the whole reset before the local wipe (no silent partial success)")
    func serverWipeNetworkErrorFailsWholeResetBeforeLocalWipe() async throws {
        let ctx = try makeContextWithOneMeasurement()
        let cloudKit = RecordingCloudKitResetService()
        let wiper = FakeServerSessionWiper(behavior: .throwOnList(URLError(.notConnectedToInternet)))
        let service = makeService(ctx, cloudKit: cloudKit, wiper: wiper)

        do {
            try await service.performFactoryReset()
            Issue.record("Expected factory reset to throw on a network wipe error")
        } catch let DeletionError.serverSessionError(underlying) {
            #expect((underlying as? URLError)?.code == .notConnectedToInternet)
        } catch {
            Issue.record("Expected DeletionError.serverSessionError, got \(error)")
        }

        // Nothing was deleted anywhere: server wipe is the first phase.
        let remaining = try ctx.fetch(FetchDescriptor<StressMeasurement>())
        #expect(remaining.count == 1)
        #expect(cloudKit.databaseResetCallCount == 0)
    }
}
