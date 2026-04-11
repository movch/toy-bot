import Foundation

extension AgentSession.SessionError {
    var userFacingMessage: String {
        switch self {
        case .emptyInput:
            return "Please enter a non-empty message."
        }
    }
}

extension RequestBuilderError {
    var userFacingMessage: String {
        switch self {
        case .invalidURL:
            return "Invalid provider URL. Check --base-url or TOYBOT_BASE_URL."
        }
    }
}

extension OpenAIClientError {
    var userFacingMessage: String {
        switch self {
        case let .failedToBuildRequest(underlying):
            return "Failed to build provider request. \(ErrorFormatter.userMessage(for: underlying))"
        case .emptyResponse:
            return "The provider returned an empty response."
        }
    }
}
