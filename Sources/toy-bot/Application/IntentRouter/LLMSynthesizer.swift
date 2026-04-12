struct LLMSynthesizer: Synthesizer {
    private let llmClient: LLMClient

    init(llmClient: LLMClient) {
        self.llmClient = llmClient
    }

    func synthesize(history: [Message], collectedContext: String) async throws -> Message {
        var synthHistory = history

        if !collectedContext.isEmpty {
            let contextMessage = Constants.synthesizerPrompt + "\n" + collectedContext
            synthHistory.append(.system(content: contextMessage))
        }

        var response = try await llmClient.sendMessage(
            history: synthHistory,
            tools: [],
            profile: .balanced
        )

        let firstTrimmed = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if firstTrimmed.isEmpty,
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
}
