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

    private let client: StressAPIClient
    /// Nil-coalesced inside the body — a default-argument expression would
    /// evaluate the @MainActor `StressAPIClient()` in a nonisolated context.
    init(client: StressAPIClient? = nil) {
        self.client = client ?? StressAPIClient()
    }

    func send(_ text: String) async {
        await run(text: text)
    }

    /// Test seam: same flow shape as `send`, with the stream call elided.
    func sendForTesting(
        _ text: String,
        stream: @escaping @Sendable (AgentChatEvent) -> Void
    ) async {
        messages.append(AgentMessage(role: "user", text: text))
        isStreaming = true
        stream(.content("ok"))
        stream(.done)
        isStreaming = false
    }

    private func run(text: String) async {
        errorText = nil
        messages.append(AgentMessage(role: "user", text: text))
        let assistant = AgentMessage(role: "assistant", text: "")
        // The row index must be captured BEFORE appending the placeholder —
        // the streaming closure and the failure path below must agree on
        // which bubble accumulates text / gets removed.
        let index = messages.count
        messages.append(assistant)
        isStreaming = true
        do {
            let returned = try await client.streamAgentChat(
                sessionID: sessionID,
                message: text,
                onEvent: { [weak self] event in
                    Task { @MainActor in self?.handle(event, assistantIndex: index) }
                }
            )
            sessionID = sessionID ?? returned
        } catch let error as AgentChatAPIError {
            errorText = error.errorDescription
            if messages.indices.contains(index), messages[index].text.isEmpty {
                messages.remove(at: index) // empty assistant bubble on failure
            }
        } catch {
            errorText = "Coach chat failed. Try again."
        }
        isStreaming = false
    }

    /// Reduces one stream event into state. `assistantIndex` pins the bubble
    /// for the in-flight turn; nil targets the last assistant bubble,
    /// creating it on first content if the turn hasn't materialized one yet
    /// (direct `handle` calls, e.g. tests).
    func handle(_ event: AgentChatEvent, assistantIndex: Int? = nil) {
        switch event {
        case .content(let text):
            if assistantIndex == nil,
               messages.lastIndex(where: { $0.role == "assistant" }) == nil {
                messages.append(AgentMessage(role: "assistant", text: ""))
            }
            if let i = assistantIndex ?? messages.lastIndex(where: { $0.role == "assistant" }) {
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
        sessionID = nil
        messages.removeAll()
        errorText = nil
    }
}
