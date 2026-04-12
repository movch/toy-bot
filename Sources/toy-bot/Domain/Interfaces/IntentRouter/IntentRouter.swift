protocol IntentRouter: Sendable {
    func classify(history: [Message]) async throws -> Intent
}
