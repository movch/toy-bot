import Foundation

enum HTTPErrorFormatter {
    static func userMessage(for error: HttpClientError) -> String {
        switch error {
        case .invalidResponse:
            return "Received a non-HTTP response from the provider."
        case let .invalidStatusCode(statusCode, bodyData):
            let details = httpBodyDetails(from: bodyData)
            return "Provider request failed with HTTP \(statusCode). \(details)"
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
