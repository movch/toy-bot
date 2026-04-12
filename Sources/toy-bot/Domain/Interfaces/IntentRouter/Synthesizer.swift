protocol Synthesizer: Sendable {
    func synthesize(history: [Message], collectedContext: String) async throws -> Message
}
