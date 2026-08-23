import Foundation
import Testing
@testable import StressMonitor

/// Pins the quick-actions suggestions fetch (derived-QA-01):
/// - `getQuickActions(stressLevel:language:coachingStyle:)` GETs the exact
///   three-param query URL with Bearer auth — the query is built via
///   URLComponents so the `?` is never percent-encoded
///   (`appendingPathComponent` encodes it, which the backend would read as a
///   literal path segment)
/// - the `{quick_actions: [...]}` envelope decodes into typed chips; `type`
///   stays a plain String so unknown server-side values decode without
///   throwing (iOS never branches on it)
/// - 401 maps to `.unauthorized`
/// - `ChatQuickActions.prompt(forServerActionId:)` mirrors the backend's own
///   prompt table verbatim, so every server-suggested chip resolves its tap
///   prompt on-device — chip taps never need the unmetered POST completion
///   route (COVERAGE row 17; the only permitted request is this GET)
@MainActor
struct StressAPIClientQuickActionsTests {

    private func makeClient(statusCode: Int, body: Data?) -> StressAPIClient {
        RequestCaptureURLProtocol.lastRequest = nil
        RequestCaptureURLProtocol.statusCode = statusCode
        RequestCaptureURLProtocol.responseBody = body
        RequestCaptureURLProtocol.responseByPath = nil
        RequestCaptureURLProtocol.capturedRequests = []
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RequestCaptureURLProtocol.self]
        return StressAPIClient(
            authService: MockAuthService(token: "fake-token"),
            baseURL: URL(string: "https://api.test")!,
            session: URLSession(configuration: config)
        )
    }

    // MARK: - getQuickActions (GET /quick-actions)

    @Test("getQuickActions GETs the exact three-param query URL with a Bearer header")
    func getQuickActionsBuildsExactQueryURL() async throws {
        let fixture = """
        {"quick_actions":[{"id":"breathing","title":"Box Breathing","type":"exercise"},{"id":"grounding","title":"5-4-3-2-1 Grounding","type":"technique"},{"id":"talk","title":"Tell Me More","type":"conversation"}]}
        """
        let client = makeClient(statusCode: 200, body: Data(fixture.utf8))

        let actions = try await client.getQuickActions(
            stressLevel: 65,
            language: "vi",
            coachingStyle: "direct"
        )

        #expect(actions.count == 3)
        #expect(actions[0].id == "breathing")
        #expect(actions[0].title == "Box Breathing")
        #expect(actions[0].type == "exercise")
        #expect(actions[1].id == "grounding")
        #expect(actions[1].title == "5-4-3-2-1 Grounding")
        #expect(actions[2].id == "talk")

        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(
            request.url?.absoluteString
                == "https://api.test/quick-actions?stress_level=65&language=vi&coaching_style=direct"
        )
        #expect(request.url?.absoluteString.contains("%3F") == false)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")
        #expect(RequestCaptureURLProtocol.capturedRequests.count == 1)
    }

    @Test("decode tolerates unknown type strings without throwing")
    func decodeToleratesUnknownTypeStrings() async throws {
        let fixture = """
        {"quick_actions":[{"id":"talk","title":"Tell Me More","type":"conversation"},{"id":"future_action","title":"New Suggestion","type":"brand_new_kind"}]}
        """
        let client = makeClient(statusCode: 200, body: Data(fixture.utf8))

        let actions = try await client.getQuickActions(
            stressLevel: 80,
            language: "en",
            coachingStyle: "supportive"
        )

        #expect(actions.count == 2)
        #expect(actions[1].id == "future_action")
        #expect(actions[1].type == "brand_new_kind")
    }

    @Test("getQuickActions maps 401 to the unauthorized error case")
    func getQuickActionsMaps401ToUnauthorized() async throws {
        let client = makeClient(statusCode: 401, body: Data("{}".utf8))

        await #expect(throws: QuickActionsAPIError.unauthorized) {
            _ = try await client.getQuickActions(
                stressLevel: 50,
                language: "en",
                coachingStyle: "supportive"
            )
        }
    }

    // MARK: - Local prompt map (server chip ids resolve prompts on-device)

    @Test("prompt(forServerActionId:) mirrors the backend prompt table for all seven ids and nil for unknown")
    func promptMapMirrorsBackendTable() {
        // Verbatim from stress-app-be/src/lib/quick-actions.ts
        // `getQuickActionPrompt` — the two tables must be updated in lockstep.
        let expected: [(id: String, prompt: String)] = [
            ("breathing", "Guide me through a box breathing exercise right now."),
            ("grounding", "Help me with the 5-4-3-2-1 grounding technique."),
            ("sleep_tips", "Give me practical tips to sleep better tonight."),
            ("mini_walk", "Suggest a simple 5-minute movement routine I can do right now."),
            ("recovery", "What recovery strategies should I focus on given my current state?"),
            ("resilience", "How can I build long-term stress resilience?"),
            ("talk", "I want to talk more about how I'm feeling right now."),
        ]
        for (id, prompt) in expected {
            #expect(ChatQuickActions.prompt(forServerActionId: id) == prompt)
        }
        #expect(ChatQuickActions.prompt(forServerActionId: "unknown_action") == nil)
    }
}
