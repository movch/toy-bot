protocol AgentSession: Sendable {
    func chat(_ userInput: String) async throws -> Message
}

enum AgentSessionError: Error {
    case emptyInput
}
