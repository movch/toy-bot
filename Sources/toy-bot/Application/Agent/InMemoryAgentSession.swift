actor InMemoryAgentSession: AgentSession {
    private let agent: any Agent
    private(set) var history: [Message]

    init(agent: any Agent) {
        self.agent = agent
        self.history = [
            Message(role: .system, content: agent.systemPrompt),
        ]
    }

    func chat(_ userInput: String) async throws -> Message {
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AgentSessionError.emptyInput
        }

        let userMessage = Message(role: .user, content: trimmed)
        history.append(userMessage)

        do {
            let assistantMessage = try await agent.llmClient.sendMessage(history: history)
            history.append(assistantMessage)
            return assistantMessage
        } catch {
            _ = history.popLast()
            throw error
        }
    }
}
