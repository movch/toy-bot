import Foundation

enum OpenAIEndpoint: Endpoint {
    case chatCompletions(request: OpenAIChatDTO.Request)

    var method: HTTPMethod {
        switch self {
        case .chatCompletions: return .post
        }
    }

    var path: String {
        switch self {
        case .chatCompletions: return "/v1/chat/completions"
        }
    }

    var headers: [String: String] {
        switch self {
        case .chatCompletions:
            return [
                "Content-Type": "application/json",
            ]
        }
    }

    var urlParams: [String: any CustomStringConvertible] {
        switch self {
        case .chatCompletions: return [:]
        }
    }

    var body: Data? {
        switch self {
        case .chatCompletions(let request):
            return try? JSONEncoder().encode(request)
        }
    }

    var authType: AuthType {
        switch self {
        case .chatCompletions:
            return .bearer
        }
    }
}

