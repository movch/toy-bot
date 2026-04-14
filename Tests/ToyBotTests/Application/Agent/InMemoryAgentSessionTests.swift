import Testing
@testable import ToyBot

struct InMemoryAgentSessionTests {
    @Test
    func emptyInputThrows() async {
        let llm = MockLLMClient(results: [])
        let registry = ToolRegistry(tools: [])
        let session = InMemoryAgentSession(
            agent: StubAgent(llmClient: llm, systemPrompt: "sys", toolRegistry: registry)
        )

        do {
            _ = try await session.chat(" ")
            Issue.record("Expected AgentSessionError.emptyInput")
        } catch AgentSessionError.emptyInput {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func llmFailureRollsBackLatestUserMessage() async {
        enum ExpectedError: Error { case boom }

        let llm = MockLLMClient(results: [.failure(ExpectedError.boom)])
        let registry = ToolRegistry(tools: [])
        let session = InMemoryAgentSession(
            agent: StubAgent(llmClient: llm, systemPrompt: "sys", toolRegistry: registry)
        )

        do {
            _ = try await session.chat("hello")
            Issue.record("Expected llm error")
        } catch ExpectedError.boom {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        let history = await session.history
        #expect(history.count == 1)
        #expect(history[0].content == "sys")
    }

    @Test
    func executesToolCallsAndContinuesWithDeterministicProfile() async throws {
        let tool = StubTool(name: "read_file") { args in
            "content for \(args)"
        }
        let llm = MockLLMClient(
            results: [
                .success(
                    .assistant(
                        content: "call tool",
                        toolCalls: [ToolCall(id: "1", toolName: "read_file", toolArguments: "path.swift")]
                    )
                ),
                .success(.assistant(content: "final answer", toolCalls: [])),
            ]
        )
        let registry = ToolRegistry(tools: [tool])
        let session = InMemoryAgentSession(
            agent: StubAgent(llmClient: llm, systemPrompt: "sys", toolRegistry: registry)
        )

        let response = try await session.chat("open file")
        let calls = await llm.calls

        #expect(response.content == "final answer")
        #expect(calls.count == 2)
        if calls.count == 2 {
            switch calls[0].profile {
            case .balanced: break
            default: Issue.record("First call should be balanced")
            }
            switch calls[1].profile {
            case .deterministic: break
            default: Issue.record("Second call should be deterministic")
            }
        }
    }

    @Test
    func unknownToolProducesExplicitErrorMessage() async throws {
        let llm = MockLLMClient(
            results: [
                .success(
                    .assistant(
                        content: "call missing tool",
                        toolCalls: [ToolCall(id: "1", toolName: "missing_tool", toolArguments: "{}")]
                    )
                ),
                .success(.assistant(content: "done", toolCalls: [])),
            ]
        )
        let registry = ToolRegistry(tools: [])
        let session = InMemoryAgentSession(
            agent: StubAgent(llmClient: llm, systemPrompt: "sys", toolRegistry: registry)
        )

        _ = try await session.chat("run something")
        let history = await session.history
        let lastToolMessage = history.first {
            if case .tool = $0 { return true }
            return false
        }

        #expect(lastToolMessage?.content.contains("no tool named \"missing_tool\"") == true)
    }
}
