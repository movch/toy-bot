import Foundation
import Testing
@testable import ToyBot

struct ErrorFormatterTests {
    @Test
    func formatsDomainErrors() {
        let message = ErrorFormatter.userMessage(for: AgentSessionError.emptyInput)
        #expect(message == "Please enter a non-empty message.")
    }

    @Test
    func formatsHttpErrorWithEmptyBody() {
        let message = ErrorFormatter.userMessage(
            for: HttpClientError.invalidStatusCode(404, nil)
        )
        #expect(message.contains("HTTP 404"))
        #expect(message.contains("Response body is empty."))
    }

    @Test
    func formatsHttpErrorWithNonUtf8Body() {
        let message = ErrorFormatter.userMessage(
            for: HttpClientError.invalidStatusCode(500, Data([0xFF, 0xD8, 0xFF]))
        )
        #expect(message.contains("not valid UTF-8"))
    }

    @Test
    func formatsUnknownErrorFallback() {
        enum Unknown: Error { case x }
        let message = ErrorFormatter.userMessage(for: Unknown.x)
        #expect(message.contains("Unexpected error"))
    }
}
