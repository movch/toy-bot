import Testing
@testable import ToyBot

struct BashToolTests {
    @Test
    func returnsValidationErrorForInvalidArguments() async throws {
        let tool = BashTool()
        let result = try await tool.execute(toolArguments: "{}")
        #expect(result.contains("invalid arguments"))
    }

    @Test
    func executesSimpleCommand() async throws {
        let tool = BashTool()
        let result = try await tool.execute(toolArguments: #"{"command":"printf hello"}"#)
        #expect(result == "hello")
    }
}
