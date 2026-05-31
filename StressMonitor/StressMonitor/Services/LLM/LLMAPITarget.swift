import Alamofire
import Foundation
import Moya

// MARK: - LLM API Target

/// Moya TargetType defining cloud LLM API endpoints.
enum LLMAPITarget: TargetType, @unchecked Sendable {
    /// GET /health — check if server is reachable
    case healthCheck
    /// POST /v1/chat/completions — streaming chat completion
    case chatCompletions(messages: [[String: String]], model: String)

    // MARK: - TargetType

    var baseURL: URL {
        URL(string: "https://hyperpolysyllabically-saronic-mee.ngrok-free.app")!
    }

    var path: String {
        switch self {
        case .healthCheck: return "/health"
        case .chatCompletions: return "/v1/chat/completions"
        }
    }

    var method: Moya.Method {
        switch self {
        case .healthCheck: return .get
        case .chatCompletions: return .post
        }
    }

    var task: Task {
        switch self {
        case .healthCheck:
            return .requestPlain
        case .chatCompletions(let messages, let model):
            return .requestParameters(
                parameters: [
                    "model": model,
                    "messages": messages,
                    "stream": true,
                ],
                encoding: JSONEncoding.default
            )
        }
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
}
