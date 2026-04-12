actor IntentRoutedSession: AgentSession {
    private let router: IntentRouter
    private let executor: ActionExecutor
    private let synthesizer: Synthesizer
    private var history: [Message]

    private let maxIterations = 5

    init(
        router: IntentRouter,
        executor: ActionExecutor,
        synthesizer: Synthesizer,
        systemPrompt: String
    ) {
        self.router = router
        self.executor = executor
        self.synthesizer = synthesizer
        self.history = [.system(content: systemPrompt)]
    }

    func chat(_ userInput: String) async throws -> Message {
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AgentSessionError.emptyInput }

        history.append(.user(content: trimmed))

        var collectedContext = ""
        var previousIntent: Intent?

        for _ in 0..<maxIterations {
            let intent = try await router.classify(history: history)

            guard intent != .directChat, intent != previousIntent else { break }
            previousIntent = intent

            print("\n🔍 Intent: \(intent.label)")

            let result = try await executor.execute(intent: intent)

            let contextEntry = "[\(intent.label)] result:\n\(result)"
            history.append(.system(content: contextEntry))
            collectedContext += "\n\n\(contextEntry)"
        }

        let response = try await synthesizer.synthesize(
            history: history,
            collectedContext: collectedContext
        )

        history.append(response)
        return response
    }
}
