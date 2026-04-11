import Foundation

enum ErrorFormatter {
    static func userMessage(for error: Error) -> String {
        switch error {
        case let error as AgentSessionError:
            return error.userFacingMessage
        case let error as RequestBuilderError:
            return error.userFacingMessage
        case let error as OpenAIClientError:
            return error.userFacingMessage
        case let error as HttpClientError:
            return HTTPErrorFormatter.userMessage(for: error)
        case let error as DecodingError:
            return FoundationErrorFormatter.userMessage(for: error)
        case let error as URLError:
            return FoundationErrorFormatter.userMessage(for: error)
        default:
            return "Unexpected error: \(error.localizedDescription)"
        }
    }
}
