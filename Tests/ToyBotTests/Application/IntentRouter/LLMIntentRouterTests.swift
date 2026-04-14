import Testing
@testable import ToyBot

struct LLMIntentRouterTests {
    @Test
    func parsesValidIntentOnFirstAttempt() async throws {
        let llm = MockLLMClient(
            results: [
                .success(
                    .assistant(
                        content: #"{"action":"search_file","path":null,"command":null,"keyword":"router","skill_id":null,"reasoning":"need file"}"#,
                        toolCalls: []
                    )
                ),
            ]
        )
        let sut = LLMIntentRouter(llmClient: llm)

        let intent = try await sut.classify(history: [.user(content: "find router")])

        #expect(intent == .searchFile(keyword: "router"))
        let calls = await llm.calls
        #expect(calls.count == 1)
    }

    @Test
    func retriesAfterInvalidJsonAndEventuallyParses() async throws {
        let llm = MockLLMClient(
            results: [
                .success(.assistant(content: "not json", toolCalls: [])),
                .success(
                    .assistant(
                        content: #"{"action":"direct_chat","path":null,"command":null,"keyword":null,"skill_id":null,"reasoning":"ready"}"#,
                        toolCalls: []
                    )
                ),
            ]
        )
        let sut = LLMIntentRouter(llmClient: llm)

        let intent = try await sut.classify(history: [.user(content: "hi")])
        let calls = await llm.calls

        #expect(intent == .directChat)
        #expect(calls.count == 2)
        if calls.count == 2 {
            #expect(calls[1].history.last?.content == Constants.intentRouterSelfCorrectionUserMessage)
        }
    }

    @Test
    func stripsMarkdownFencesBeforeJsonDecode() async throws {
        let llm = MockLLMClient(
            results: [
                .success(
                    .assistant(
                        content: """
                        ```json
                        {"action":"read_file","path":" Sources/toy-bot/ToyBot.swift ","command":null,"keyword":null,"skill_id":null,"reasoning":"need read"}
                        ```
                        """,
                        toolCalls: []
                    )
                ),
            ]
        )
        let sut = LLMIntentRouter(llmClient: llm)

        let intent = try await sut.classify(history: [.user(content: "open")])

        #expect(intent == .readFile(path: "Sources/toy-bot/ToyBot.swift"))
    }

    @Test
    func returnsDirectChatAfterMaxInvalidAttempts() async throws {
        let llm = MockLLMClient(
            results: [
                .success(.assistant(content: "bad", toolCalls: [])),
                .success(.assistant(content: "still bad", toolCalls: [])),
                .success(.assistant(content: "nope", toolCalls: [])),
            ]
        )
        let sut = LLMIntentRouter(llmClient: llm)

        let intent = try await sut.classify(history: [.user(content: "hello")])
        let calls = await llm.calls

        #expect(intent == .directChat)
        #expect(calls.count == 3)
    }
}
