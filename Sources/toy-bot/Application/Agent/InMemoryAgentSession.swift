actor InMemoryAgentSession: AgentSession {
    private let agent: any Agent
    private(set) var history: [Message]
    
    init(agent: any Agent) {
        self.agent = agent
        self.history = [
            .system(content: agent.systemPrompt),
        ]
    }
    
    func chat(_ userInput: String) async throws -> Message {
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AgentSessionError.emptyInput
        }

        history.append(.user(content: trimmed))

        var continuationAfterTools = false
        while true {
            let profile: GenerationProfile = continuationAfterTools ? .deterministic : .balanced
            let response: Message
            do {
                response = try await agent.llmClient.sendMessage(
                    history: history,
                    tools: agent.toolRegistry.allTools,
                    profile: profile
                )
            } catch {
                _ = history.popLast()
                throw error
            }

            history.append(response)

            guard case .assistant(_, let toolCalls) = response, !toolCalls.isEmpty else {
                return response
            }

            for call in toolCalls {
                print("\n🔨 Tool: \(call.toolName):")
                print("\(call.toolArguments)")
                let result = await executeToolCall(call)
                history.append(.tool(content: result, toolCallId: call.id))
            }
            continuationAfterTools = true
        }
    }
    
    private func executeToolCall(_ toolCall: ToolCall) async -> String {
        do {
            return try await agent.toolRegistry.execute(
                name: toolCall.toolName,
                toolArguments: toolCall.toolArguments
            )
        } catch let error as ToolRegistryError {
            switch error {
            case .toolNotFound(let name):
                return "Error: no tool named \"\(name)\". Use only read_file or bash."
            }
        } catch {
            return "Error executing tool: \(error.localizedDescription)"
        }
    }
}
