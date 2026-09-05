import Combine
import Foundation

// MARK: - Agent Message

/// One bubble in the Health Coach conversation. Roles are the wire strings
/// ("user" | "assistant") — this chat posts a single `message` per turn and
/// never replays history client-side, so no full `ChatMessage` model needed.
struct AgentMessage: Identifiable, Equatable, Sendable {
    let id = UUID()
    let role: String
    var text: String
}

// MARK: - Agent Chat View Model

/// Drives the Health Coach chat screen: one user turn → streamed assistant
/// reply over `POST /agent/chat`. Session id is adopted from the first
/// metadata event so the server keeps conversation context across turns.
@MainActor
final class AgentChatViewModel: ObservableObject {

    @Published var messages: [AgentMessage] = []
    @Published var isStreaming = false
    @Published var errorText: String?

    private(set) var creditsRemaining: Int?
    private(set) var sessionID: UUID?
    /// Bumped by `startNewConversation`. Events (and session-id adoption)
    /// from an in-flight turn carry the generation they started under; a
    /// mismatch means the conversation was reset and the event is dropped.
    private var generation = 0

    private let client: StressAPIClient
    /// Nil-coalesced inside the body — a default-argument expression would
    /// evaluate the @MainActor `StressAPIClient()` in a nonisolated context.
    init(client: StressAPIClient? = nil) {
        self.client = client ?? StressAPIClient()
    }

    /// Signature of `StressAPIClient.streamAgentChat`, injectable so tests
    /// can park a stream mid-turn and drive the reset race deterministically.
    typealias AgentChatStream = @Sendable (
        _ sessionID: UUID?,
        _ message: String,
        _ onEvent: @escaping @Sendable (AgentChatEvent) -> Void
    ) async throws -> UUID?

    func send(_ text: String, stream: AgentChatStream? = nil) async {
        await run(text: text, stream: stream ?? { sessionID, message, onEvent in
            try await self.client.streamAgentChat(
                sessionID: sessionID, message: message, onEvent: onEvent)
        })
    }

    /// Test seam: same flow as `send`, with the stream call elided.
    func sendForTesting(
        _ text: String,
        stream: @escaping @Sendable (AgentChatEvent) -> Void
    ) async {
        await run(text: text) { _, _, onEvent in
            stream(.content("ok"))
            stream(.done)
            return nil
        }
    }

    private func run(text: String, stream: AgentChatStream) async {
        errorText = nil
        messages.append(AgentMessage(role: "user", text: text))
        let assistant = AgentMessage(role: "assistant", text: "")
        // Identity over position: `New` mid-stream or the failure path can
        // remove rows while events are still in flight, so the streaming
        // closure and the failure path resolve the SAME bubble by id — a
        // captured index would trap on a reset list.
        let assistantID = assistant.id
        messages.append(assistant)
        let generation = self.generation
        isStreaming = true
        do {
            let returned = try await stream(sessionID, text) { [weak self] event in
                Task { @MainActor [weak self] in
                    guard let self, generation == self.generation else { return }
                    self.handle(event, assistantID: assistantID)
                }
            }
            // The returned id belongs to the conversation this turn started
            // in — after a mid-stream reset it must not be adopted.
            if generation == self.generation {
                sessionID = sessionID ?? returned
            }
        } catch let error as AgentChatAPIError {
            errorText = error.errorDescription
            removeEmptyAssistantBubble(id: assistantID)
        } catch {
            errorText = "Coach chat failed. Try again."
            removeEmptyAssistantBubble(id: assistantID)
        }
        isStreaming = false
    }

    private func removeEmptyAssistantBubble(id: UUID) {
        if let i = messages.firstIndex(where: { $0.id == id }), messages[i].text.isEmpty {
            messages.remove(at: i) // empty assistant bubble on failure
        }
    }

    /// Reduces one stream event into state. `assistantID` pins the bubble
    /// for the in-flight turn; nil targets the last assistant bubble,
    /// creating it on first content if the turn hasn't materialized one yet
    /// (direct `handle` calls, e.g. tests). An id that no longer resolves
    /// (reset or failed turn) silently drops the event instead of trapping.
    func handle(_ event: AgentChatEvent, assistantID: UUID? = nil) {
        switch event {
        case .content(let text):
            var target = assistantID ?? messages.last(where: { $0.role == "assistant" })?.id
            if target == nil {
                let bubble = AgentMessage(role: "assistant", text: "")
                messages.append(bubble)
                target = bubble.id
            }
            if let i = messages.firstIndex(where: { $0.id == target }) {
                messages[i].text += text
            }
        case .metadata(let session, let credits, _):
            if let session { sessionID = sessionID ?? session }
            if let credits { creditsRemaining = credits }
        case .done:
            break
        }
    }

    func startNewConversation() {
        // Bump first: in-flight events and session-id adoption from the old
        // conversation compare generations and drop instead of mutating the
        // fresh state.
        generation += 1
        sessionID = nil
        messages.removeAll()
        errorText = nil
    }
}
