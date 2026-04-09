import Foundation

enum ErrorFormatter {
    static func userMessage(for error: Error) -> String {
        switch error {
        case AgentSession.SessionError.emptyInput:
            return "Please enter a non-empty message."

        case RequestBuilderError.invalidURL:
            return "Invalid provider URL. Check --base-url or TOYBOT_BASE_URL."

        case let OpenAIClientError.failedToBuildRequest(underlying):
            return "Failed to build provider request. \(userMessage(for: underlying))"
        case OpenAIClientError.emptyResponse:
            return "The provider returned an empty response."

        case HttpClientError.invalidResponse:
            return "Received a non-HTTP response from the provider."
        case let HttpClientError.invalidStatusCode(statusCode, bodyData):
            let details = httpBodyDetails(from: bodyData)
            return "Provider request failed with HTTP \(statusCode). \(details)"

        case let decodingError as DecodingError:
            return "Failed to decode provider response: \(String(describing: decodingError))."

        case let urlError as URLError:
            return "Network error: \(urlError.localizedDescription)"

        default:
            return "Unexpected error: \(error.localizedDescription)"
        }
    }

    private static func httpBodyDetails(from data: Data?) -> String {
        guard let data, !data.isEmpty else {
            return "Response body is empty."
        }

        guard var text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return "Response body is not valid UTF-8 text."
        }

        let maxLength = 3_000
        if text.count > maxLength {
            text = String(text.prefix(maxLength)) + "..."
        }

        return "Response body: \(text)"
    }
}
