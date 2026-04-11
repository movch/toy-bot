import Foundation

enum FoundationErrorFormatter {
    static func userMessage(for error: DecodingError) -> String {
        "Failed to decode provider response: \(String(describing: error))."
    }

    static func userMessage(for error: URLError) -> String {
        "Network error: \(error.localizedDescription)"
    }
}
