import Testing
@testable import ToyBot

struct LLMSynthesizerTests {
    @Test
    func synthesizeWithoutToolContextUsesSingleBalancedCall() async throws {
        let llm = MockLLMClient(results: [.success(.assistant(content: "ok", toolCalls: []))])
        let sut = LLMSynthesizer(llmClient: llm)

        let response = try await sut.synthesize(history: [.user(content: "hello")], collectedContext: " \n ")
        let calls = await llm.calls

        #expect(calls.count == 1)
        #expect(calls[0].profile == .balanced)
        #expect(response.content == "ok")
    }

    @Test
    func synthesizeRetriesThenReturnsDeterministicFallback() async throws {
        let llm = MockLLMClient(
            results: [
                .success(.assistant(content: " ", toolCalls: [])),
                .success(.assistant(content: "\n", toolCalls: [])),
                .success(.assistant(content: "\t", toolCalls: [])),
            ]
        )
        let sut = LLMSynthesizer(llmClient: llm)
        let context = String(repeating: "ctx-", count: 5_000)

        let response = try await sut.synthesize(
            history: [.system(content: "sys"), .user(content: "summarize")],
            collectedContext: context
        )
        let calls = await llm.calls

        #expect(calls.count == 3)
        #expect(calls[0].profile == .balanced)
        #expect(calls[1].profile == .deterministic)
        #expect(calls[2].profile == .deterministic)
        #expect(response.content.contains("The model returned an empty reply after several attempts"))
        #expect(response.content.contains("User request: summarize"))
    }

    @Test
    func synthesizeFallsBackToFullHistoryWhenNoUserMessage() async throws {
        let llm = MockLLMClient(
            results: [
                .success(.assistant(content: "", toolCalls: [])),
                .success(.assistant(content: "recovered", toolCalls: [])),
            ]
        )
        let sut = LLMSynthesizer(llmClient: llm)

        let response = try await sut.synthesize(
            history: [.system(content: "only system")],
            collectedContext: "tool output"
        )
        let calls = await llm.calls

        #expect(calls.count == 2)
        #expect(calls[0].profile == .balanced)
        #expect(calls[1].profile == .deterministic)
        #expect(calls[0].history.last?.content.contains("Collected context") == true)
        #expect(response.content == "recovered")
    }
}
