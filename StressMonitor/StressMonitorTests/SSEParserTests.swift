import Testing
@testable import StressMonitor

/// Pins the D-05 contract: the terminal SSE metadata event carries a
/// `quick_actions` string array that the chat UI surfaces as suggestion
/// chips. Field name is backend-defined — a rename breaks silently.
struct SSEParserTests {

    @Test("metadata event with quick_actions populates quickActions")
    func metadataEventParsesQuickActions() {
        let line = #"data: {"type":"metadata","session_id":"00000000-0000-0000-0000-000000000000","credits_remaining":42,"model_used":"openai/gpt-oss-20b:free","quick_actions":["breathe","reflect"]}"#

        let event = SSEParser.parse(line: line)

        guard case .metadata(let metadata) = event else {
            Issue.record("expected .metadata event, got \(String(describing: event))")
            return
        }
        #expect(metadata.quickActions == ["breathe", "reflect"])
    }

    @Test("metadata event without quick_actions leaves quickActions nil (backward compatible)")
    func metadataEventWithoutQuickActionsIsNil() {
        let line = #"data: {"type":"metadata","session_id":"00000000-0000-0000-0000-000000000000","credits_remaining":42,"model_used":"openai/gpt-oss-20b:free"}"#

        let event = SSEParser.parse(line: line)

        guard case .metadata(let metadata) = event else {
            Issue.record("expected .metadata event, got \(String(describing: event))")
            return
        }
        #expect(metadata.quickActions == nil)
    }

    @Test("metadata event preserves sessionId, creditsRemaining, and modelUsed")
    func metadataEventPreservesExistingFields() {
        let line = #"data: {"type":"metadata","session_id":"12345678-1234-1234-1234-123456789012","credits_remaining":7,"model_used":"openai/gpt-oss-20b:free"}"#

        let event = SSEParser.parse(line: line)

        guard case .metadata(let metadata) = event else {
            Issue.record("expected .metadata event, got \(String(describing: event))")
            return
        }
        #expect(metadata.sessionId?.uuidString == "12345678-1234-1234-1234-123456789012")
        #expect(metadata.creditsRemaining == 7)
        #expect(metadata.modelUsed == "openai/gpt-oss-20b:free")
    }
}
