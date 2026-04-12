actor IntentRoutedSession: AgentSession {
    private let router: IntentRouter
    private let executor: ActionExecutor
    private let synthesizer: Synthesizer
    private let deterministicResolver: DeterministicIntentResolver
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
        self.deterministicResolver = DeterministicIntentResolver()
        self.history = [.system(content: systemPrompt)]
    }

    func chat(_ userInput: String) async throws -> Message {
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AgentSessionError.emptyInput }

        history.append(.user(content: trimmed))

        var collectedContext = ""
        var lastIntent: Intent?
        var lastResult: String?

        for _ in 0..<maxIterations {
            let intent: Intent

            if let prev = lastIntent,
               let prevResult = lastResult,
               let deterministic = deterministicResolver.resolve(after: prev, result: prevResult) {
                intent = deterministic
                print("  ⚡ auto: \(intent.label)")
            } else {
                intent = try await router.classify(history: history)
            }

            if intent == .directChat { break }

            print("\n🔍 Intent: \(intent.label)")

            let result = try await executor.execute(intent: intent)
            lastIntent = intent
            lastResult = result

            let contextEntry = "[\(intent.label)] result:\n\(result)"
            history.append(.system(content: contextEntry))
            collectedContext += "\n\n\(contextEntry)"
        }

        let response = try await synthesizer.synthesize(
            history: history,
            collectedContext: collectedContext
        )

        let contentTrimmed = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalMessage: Message
        if contentTrimmed.isEmpty {
            var body = Constants.synthesizerEmptyReplyFallback
            if !collectedContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                body += "\n\n---\n" + collectedContext
            }
            finalMessage = .assistant(content: body, toolCalls: [])
        } else {
            finalMessage = response
        }

        history.append(finalMessage)
        return finalMessage
    }
}
