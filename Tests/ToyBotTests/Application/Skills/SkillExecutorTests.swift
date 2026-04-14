import Testing
@testable import ToyBot

struct SkillExecutorTests {
    @Test
    func executeBuildsWorkerHistoryWithExamplesAndContext() async throws {
        let skill = Skill(
            metadata: .init(id: "summarize", name: "Summarize", description: "desc"),
            systemPrompt: "System skill prompt",
            examples: [
                .init(userMessage: "u1", assistantResponse: "a1"),
                .init(userMessage: "u2", assistantResponse: "a2"),
            ],
            outputFormat: .freeText
        )
        let registry = StubSkillRegistry(
            metadata: [skill.metadata],
            skillsById: ["summarize": skill]
        )
        let llm = MockLLMClient(results: [.success(.assistant(content: "done", toolCalls: []))])
        let sut = SkillExecutor(llmClient: llm, skillRegistry: registry)

        let result = try await sut.execute(
            skillId: "summarize",
            userRequest: "Please summarize",
            collectedContext: "Tool output"
        )
        let calls = await llm.calls

        #expect(result == "done")
        #expect(calls.count == 1)
        #expect(calls[0].profile == .balanced)
        #expect(calls[0].structuredOutput == .none)
        #expect(calls[0].history.first?.content == "System skill prompt")
        #expect(calls[0].history.last?.content.contains("Context:\nTool output") == true)
    }

    @Test
    func executeUsesJsonStructuredOutputForJsonSkill() async throws {
        let skill = Skill(
            metadata: .init(id: "json", name: "JSON", description: "desc"),
            systemPrompt: "sys",
            examples: [],
            outputFormat: .json
        )
        let registry = StubSkillRegistry(skillsById: ["json": skill])
        let llm = MockLLMClient(results: [.success(.assistant(content: "{}", toolCalls: []))])
        let sut = SkillExecutor(llmClient: llm, skillRegistry: registry)

        _ = try await sut.execute(skillId: "json", userRequest: "req")
        let calls = await llm.calls

        #expect(calls[0].structuredOutput == .jsonObject)
    }
}
