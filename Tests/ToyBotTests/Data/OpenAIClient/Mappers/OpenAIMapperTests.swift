import Foundation
import Testing
@testable import ToyBot

struct OpenAIMapperTests {
    @Test
    func messageMapsToDtoAndBack() {
        let message = Message.assistant(
            content: "answer",
            toolCalls: [ToolCall(id: "1", toolName: "read_file", toolArguments: "{\"path\":\"a\"}")]
        )

        let dto = message.openAIChatDTO
        let mappedBack = dto.domain

        #expect(dto.role == .assistant)
        #expect(dto.toolCalls?.count == 1)
        #expect(mappedBack.content == "answer")
        if case .assistant(_, let toolCalls) = mappedBack {
            #expect(toolCalls.count == 1)
            #expect(toolCalls[0].toolName == "read_file")
        } else {
            Issue.record("Expected assistant message")
        }
    }

    @Test
    func toolSchemaReturnsNilForInvalidJson() {
        let tool = StubTool(name: "x") { _ in "" }
        struct BadTool: Tool {
            let name = "bad"
            let description = "bad"
            let parametersSchema = "{not-json"
            func execute(toolArguments: String) async throws -> String { "" }
        }

        #expect(tool.openAIChatDTOSchema != nil)
        #expect(BadTool().openAIChatDTOSchema == nil)
    }

    @Test
    func requestInitializerIncludesToolsWhenPresent() {
        let tool = StubTool(name: "read_file") { _ in "" }
        let request = OpenAIChatDTO.Request(
            model: "m",
            history: [.user(content: "hi")],
            profile: .balanced,
            tools: [tool],
            responseFormat: .jsonObject()
        )

        #expect(request.model == "m")
        #expect(request.messages.count == 1)
        #expect(request.tools?.count == 1)
        #expect(request.responseFormat?.type == "json_object")
    }

    @Test
    func responseFirstDomainMessageReadsFirstChoice() {
        let response = OpenAIChatDTO.Response(
            choices: [
                .init(message: .init(role: .assistant, content: "one", toolCalls: nil, toolCallId: nil)),
                .init(message: .init(role: .assistant, content: "two", toolCalls: nil, toolCallId: nil)),
            ]
        )

        #expect(response.firstDomainMessage?.content == "one")
    }
}
