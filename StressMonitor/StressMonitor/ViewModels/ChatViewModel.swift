import Foundation
import Observation

// MARK: - Chat ViewModel

/// Manages chat message state, streaming responses, and LLM interaction.
@Observable
@MainActor
final class ChatViewModel {

    // MARK: - State

    var messages: [ChatMessage] = []
    var currentStreamingText: String = ""
    var isLoading = false
    var errorMessage: String?
    var isAvailable: Bool = false

    // MARK: - Quick Actions

    var quickActions: [ChatQuickAction] {
        ChatQuickActions.actions(for: stressResult?.category)
    }

    // MARK: - Private State

    private let llmService: LLMServiceProtocol
    private var streamingTask: Task<Void, Never>?
    private let contextBuilder = ChatContextBuilder.self

    private var stressResult: StressResult?
    private var baseline: PersonalBaseline?
    private var recentHistory: [StressMeasurement] = []

    /// Max messages before proactive trim to avoid context overflow
    private let maxMessages = 20

    // MARK: - Initialization

    init(
        stressResult: StressResult?,
        baseline: PersonalBaseline?,
        recentHistory: [StressMeasurement] = []
    ) {
        self.stressResult = stressResult
        self.baseline = baseline
        self.recentHistory = recentHistory

        // Supabase-first strategy: Supabase Edge Function → Apple Intelligence → unavailable
        let supabaseService = SupabaseLLMService()
        self.llmService = supabaseService
        self.isAvailable = true
    }

    // MARK: - Send Message

    /// Send a user message and stream the AI response
    func send(_ text: String) {
        // Cancel any in-flight streaming before starting new one
        cancelResponse()

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        errorMessage = nil

        // Proactive context trim
        trimOldMessagesIfNeeded()

        streamingTask = Task { [weak self] in
            guard let self else { return }
            await self.streamResponse()
        }
    }

    /// Send a quick action prompt
    func sendQuickAction(_ action: ChatQuickAction) {
        send(action.prompt)
    }

    // MARK: - Streaming

    private func streamResponse() async {
        isLoading = true
        currentStreamingText = ""
        defer {
            if !Task.isCancelled {
                isLoading = false
                currentStreamingText = ""
            }
        }

        // Build stress context for the backend (backend builds system prompt from this)
        SupabaseLLMService.currentStressContext = StressContextPayload.build(
            stressResult: stressResult,
            baseline: baseline,
            recentHistory: recentHistory
        )

        // systemPrompt is ignored by SupabaseLLMService — backend builds it
        let systemPrompt = contextBuilder.buildSystemPrompt(
            stressResult: stressResult,
            baseline: baseline,
            recentHistory: recentHistory
        )

        do {
            let stream = try await llmService.send(
                messages: messages,
                systemPrompt: systemPrompt
            )

            for try await token in stream {
                if Task.isCancelled { break }
                currentStreamingText += token
            }

            if !currentStreamingText.isEmpty {
                let response = ChatMessage(role: .assistant, content: currentStreamingText)
                messages.append(response)
            }
        } catch let error as LLMServiceError {
            if case .exceededContext = error {
                messages.removeAll()
                errorMessage = error.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Context Management

    /// Trim oldest messages to stay within budget, keeping system context fresh
    private func trimOldMessagesIfNeeded() {
        guard messages.count > maxMessages else { return }
        // Keep last N messages (remove oldest user/assistant pairs)
        let trimCount = messages.count - maxMessages
        messages.removeFirst(trimCount)
    }

    // MARK: - Cancellation

    /// Cancel the current streaming response
    func cancelResponse() {
        guard streamingTask != nil else { return }
        streamingTask?.cancel()
        streamingTask = nil

        if !currentStreamingText.isEmpty {
            let partial = ChatMessage(role: .assistant, content: currentStreamingText)
            messages.append(partial)
        }
        currentStreamingText = ""
        isLoading = false
    }

    /// Clear all messages and start fresh
    func clearConversation() {
        cancelResponse()
        messages.removeAll()
        errorMessage = nil
    }
}

// MARK: - Unavailable LLM Service (Fallback)

/// Fallback service for devices without Apple Intelligence
private final class UnavailableLLMService: LLMServiceProtocol, Sendable {
    func isAvailable() -> Bool { false }

    func send(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish(throwing: LLMServiceError.unavailable(
            reason: "AI Chat requires iOS 26 or later with Apple Intelligence enabled."
        ))}
    }
}
