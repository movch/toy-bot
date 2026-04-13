/// Executes a skill in an isolated worker session.
///
/// The worker session contains only:
///   1. The skill's system prompt
///   2. Few-shot examples (injected as user/assistant message pairs)
///   3. The current user request + any previously collected tool context
///
/// The main chat history is intentionally excluded so the model
/// stays focused and doesn't get confused by unrelated context.
struct SkillExecutor: Sendable {
    private let llmClient: LLMClient
    private let skillRegistry: any SkillRegistry

    init(llmClient: LLMClient, skillRegistry: any SkillRegistry) {
        self.llmClient = llmClient
        self.skillRegistry = skillRegistry
    }

    func execute(
        skillId: String,
        userRequest: String,
        collectedContext: String? = nil
    ) async throws -> String {
        let skill = try skillRegistry.loadSkill(id: skillId)

        let structuredOutput: LLMStructuredOutput = switch skill.outputFormat {
        case .json:     .jsonObject
        case .freeText: .none
        }

        let history = buildWorkerHistory(
            skill: skill,
            userRequest: userRequest,
            collectedContext: collectedContext
        )

        let response = try await llmClient.sendMessage(
            history: history,
            tools: [],
            profile: .balanced,
            structuredOutput: structuredOutput
        )

        return response.content
    }
}

// MARK: - Worker history

private extension SkillExecutor {

    func buildWorkerHistory(
        skill: Skill,
        userRequest: String,
        collectedContext: String?
    ) -> [Message] {
        var history: [Message] = [.system(content: skill.systemPrompt)]

        for example in skill.examples {
            history.append(.user(content: example.userMessage))
            history.append(.assistant(content: example.assistantResponse, toolCalls: []))
        }

        var userContent = userRequest
        if let ctx = collectedContext,
           !ctx.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userContent += "\n\nContext:\n" + ctx
        }
        history.append(.user(content: userContent))

        return history
    }
}
