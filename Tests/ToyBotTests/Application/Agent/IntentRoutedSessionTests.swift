import Testing
@testable import ToyBot

struct IntentRoutedSessionTests {
    @Test
    func emptyInputThrows() async {
        let router = StubIntentRouter(intents: [.directChat])
        let executor = StubActionExecutor(results: [])
        let synthesizer = StubSynthesizer(output: .assistant(content: "unused", toolCalls: []))
        let session = IntentRoutedSession(
            router: router,
            executor: executor,
            synthesizer: synthesizer,
            systemPrompt: "system"
        )

        do {
            _ = try await session.chat("   \n")
            Issue.record("Expected AgentSessionError.emptyInput")
        } catch AgentSessionError.emptyInput {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func deterministicResolverAvoidsExtraRouterCalls() async throws {
        let router = StubIntentRouter(intents: [.searchFile(keyword: "ToyBot.swift")])
        let executor = StubActionExecutor(
            results: [
                "Sources/toy-bot/ToyBot.swift",
                "actor ToyBot {}",
            ]
        )
        let synthesizer = StubSynthesizer(output: .assistant(content: "final summary", toolCalls: []))
        let session = IntentRoutedSession(
            router: router,
            executor: executor,
            synthesizer: synthesizer,
            systemPrompt: "system"
        )

        let response = try await session.chat("summarize file")
        let classifyCallCount = await router.classifyCallCount
        let executorIntents = await executor.receivedIntents
        let synthCalls = await synthesizer.calls

        #expect(response.content == "final summary")
        #expect(classifyCallCount == 1)
        #expect(executorIntents.count == 2)
        #expect(executorIntents[0] == .searchFile(keyword: "ToyBot.swift"))
        #expect(executorIntents[1] == .readFile(path: "Sources/toy-bot/ToyBot.swift"))
        #expect(synthCalls.count == 1)
        #expect(synthCalls[0].context.contains("[search_file(ToyBot.swift)] result:"))
        #expect(synthCalls[0].context.contains("[read_file(Sources/toy-bot/ToyBot.swift)] result:"))
    }

    @Test
    func emptySynthesizerResponseUsesSessionFallback() async throws {
        let router = StubIntentRouter(intents: [.directChat])
        let executor = StubActionExecutor(results: [])
        let synthesizer = StubSynthesizer(output: .assistant(content: " \n", toolCalls: []))
        let session = IntentRoutedSession(
            router: router,
            executor: executor,
            synthesizer: synthesizer,
            systemPrompt: "system"
        )

        let response = try await session.chat("hello")

        #expect(response.content.contains("The model returned an empty reply."))
    }

    @Test
    func emptySynthesizerResponseAppendsCollectedContext() async throws {
        let router = StubIntentRouter(intents: [.bash(command: "ls"), .directChat])
        let executor = StubActionExecutor(results: ["a.txt\nb.txt"])
        let synthesizer = StubSynthesizer(output: .assistant(content: " ", toolCalls: []))
        let session = IntentRoutedSession(
            router: router,
            executor: executor,
            synthesizer: synthesizer,
            systemPrompt: "system"
        )

        let response = try await session.chat("show files")

        #expect(response.content.contains("The model returned an empty reply."))
        #expect(response.content.contains("[bash(ls)] result:"))
    }

    @Test
    func skillIntentWithoutExecutorReturnsConfiguredMessage() async throws {
        let router = StubIntentRouter(intents: [.skill(id: "review")])
        let executor = StubActionExecutor(results: [])
        let synthesizer = StubSynthesizer(output: .assistant(content: "unused", toolCalls: []))
        let session = IntentRoutedSession(
            router: router,
            executor: executor,
            synthesizer: synthesizer,
            systemPrompt: "system"
        )

        let response = try await session.chat("review this")
        #expect(response.content.contains("no SkillExecutor is configured"))
    }

    @Test
    func skillIntentWithExecutorReturnsSkillOutput() async throws {
        let skill = Skill(
            metadata: .init(id: "review", name: "Review", description: "desc"),
            systemPrompt: "review prompt",
            examples: [],
            outputFormat: .freeText
        )
        let llm = MockLLMClient(results: [.success(.assistant(content: "skill-output", toolCalls: []))])
        let skillExecutor = SkillExecutor(
            llmClient: llm,
            skillRegistry: StubSkillRegistry(metadata: [skill.metadata], skillsById: ["review": skill])
        )
        let router = StubIntentRouter(intents: [.skill(id: "review")])
        let executor = StubActionExecutor(results: [])
        let synthesizer = StubSynthesizer(output: .assistant(content: "unused", toolCalls: []))
        let session = IntentRoutedSession(
            router: router,
            executor: executor,
            synthesizer: synthesizer,
            skillExecutor: skillExecutor,
            systemPrompt: "system"
        )

        let response = try await session.chat("review this")
        #expect(response.content == "skill-output")
    }

    @Test
    func stopsAtMaxIterationsThenSynthesizes() async throws {
        let router = StubIntentRouter(
            intents: [
                .bash(command: "c1"),
                .bash(command: "c2"),
                .bash(command: "c3"),
                .bash(command: "c4"),
                .bash(command: "c5"),
                .bash(command: "c6"),
            ]
        )
        let executor = StubActionExecutor(results: ["1", "2", "3", "4", "5", "6"])
        let synthesizer = StubSynthesizer(output: .assistant(content: "done", toolCalls: []))
        let session = IntentRoutedSession(
            router: router,
            executor: executor,
            synthesizer: synthesizer,
            systemPrompt: "system"
        )

        let response = try await session.chat("run commands")
        let intents = await executor.receivedIntents
        let calls = await synthesizer.calls

        #expect(response.content == "done")
        #expect(intents.count == 5)
        #expect(calls.count == 1)
    }
}
