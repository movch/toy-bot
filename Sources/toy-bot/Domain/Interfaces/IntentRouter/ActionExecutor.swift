protocol ActionExecutor: Sendable {
    func execute(intent: Intent) async throws -> String
}
