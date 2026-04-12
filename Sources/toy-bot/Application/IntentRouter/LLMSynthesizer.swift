struct LLMSynthesizer: Synthesizer {
    private let llmClient: LLMClient

    /// Keeps small models within a predictable context window for synthesis.
    private let synthesisContextMaxChars = 14_000
    private let synthesisRetryContextMaxChars = 6_000

    init(llmClient: LLMClient) {
        self.llmClient = llmClient
    }

    func synthesize(history: [Message], collectedContext: String) async throws -> Message {
        let trimmedContext = collectedContext.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedContext.isEmpty {
            return try await synthesizeWithoutToolContext(history: history)
        }

        guard let userRequest = Self.lastUserContent(in: history) else {
            return try await synthesizeWithFullHistory(history: history, collectedContext: collectedContext)
        }

        let forModel = Self.truncate(collectedContext, maxChars: synthesisContextMaxChars)

        var focused: [Message] = [
            .system(content: Constants.synthesizerFocusedSystemPrompt),
            .user(content: "User request:\n\(userRequest)"),
            .user(content: "Tool and file context:\n\(forModel)"),
        ]

        var response = try await llmClient.sendMessage(
            history: focused,
            tools: [],
            profile: .balanced
        )

        if Self.isContentEmpty(response) {
            focused.append(.system(content: Constants.synthesizerNonEmptyRetryPrompt))
            response = try await llmClient.sendMessage(
                history: focused,
                tools: [],
                profile: .deterministic
            )
        }

        if Self.isContentEmpty(response) {
            let shorter = Self.truncate(collectedContext, maxChars: synthesisRetryContextMaxChars)
            focused = [
                .system(content: Constants.synthesizerFocusedSystemPrompt),
                .user(content: "User request:\n\(userRequest)"),
                .user(content: "Tool and file context (shortened):\n\(shorter)"),
                .system(content: Constants.synthesizerNonEmptyRetryPrompt),
            ]
            response = try await llmClient.sendMessage(
                history: focused,
                tools: [],
                profile: .deterministic
            )
        }

        if Self.isContentEmpty(response) {
            return .assistant(
                content: Self.deterministicFallback(userRequest: userRequest, context: collectedContext),
                toolCalls: []
            )
        }

        return response
    }

    private func synthesizeWithoutToolContext(history: [Message]) async throws -> Message {
        try await llmClient.sendMessage(
            history: history,
            tools: [],
            profile: .balanced
        )
    }

    private func synthesizeWithFullHistory(history: [Message], collectedContext: String) async throws -> Message {
        var synthHistory = history
        let contextMessage = Constants.synthesizerPrompt + "\n" + collectedContext
        synthHistory.append(.system(content: contextMessage))

        var response = try await llmClient.sendMessage(
            history: synthHistory,
            tools: [],
            profile: .balanced
        )

        if Self.isContentEmpty(response),
           !collectedContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            synthHistory.append(.system(content: Constants.synthesizerNonEmptyRetryPrompt))
            response = try await llmClient.sendMessage(
                history: synthHistory,
                tools: [],
                profile: .deterministic
            )
        }

        return response
    }

    private static func isContentEmpty(_ message: Message) -> Bool {
        message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func lastUserContent(in history: [Message]) -> String? {
        for message in history.reversed() {
            if case .user(let content) = message {
                return content
            }
        }
        return nil
    }

    private static func truncate(_ string: String, maxChars: Int) -> String {
        guard string.count > maxChars else { return string }
        return String(string.prefix(maxChars)) + "\n\n[truncated for synthesis]"
    }

    private static func deterministicFallback(userRequest: String, context: String) -> String {
        let excerpt = String(context.prefix(4_000))
        let suffix = context.count > 4_000 ? "\n\n…" : ""
        return """
            The model returned an empty reply after several attempts. User request: \(userRequest)

            Excerpt of gathered context:

            \(excerpt)\(suffix)
            """
    }
}
