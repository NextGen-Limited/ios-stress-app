import Foundation

// MARK: - SSE Event

/// Parsed result from a single SSE data line.
enum SSEEvent {
    /// Content token received from streaming response
    case content(String)
    /// Stream completed successfully
    case done
    /// Server reported an error
    case error(String)
}

// MARK: - SSE Parser

/// Parses individual SSE lines from an OpenAI-compatible streaming response.
struct SSEParser {

    /// Parse a single SSE line into an event.
    /// - Parameter line: Raw line from the SSE stream (e.g. "data: {\"choices\":...}")
    /// - Returns: Parsed event, or nil if line is not a data line or unparseable.
    nonisolated static func parse(line: String) -> SSEEvent? {
        // Only process lines starting with "data: "
        guard line.hasPrefix("data: ") else { return nil }

        let payload = String(line.dropFirst(6))

        // Check for stream end sentinel
        if payload == "[DONE]" { return .done }

        // Attempt JSON parse
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Check for error in response
        if let errorMsg = json["error"] as? String {
            return .error(errorMsg)
        }

        // Extract content from OpenAI-compatible format: choices[0].delta.content
        if let choices = json["choices"] as? [[String: Any]],
           let delta = choices.first?["delta"] as? [String: Any],
           let content = delta["content"] as? String {
            return .content(content)
        }

        // Extract content from LLM Gateway format: {"token": "..."}
        if let token = json["token"] as? String {
            return .content(token)
        }

        return nil
    }
}
