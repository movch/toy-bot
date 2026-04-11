import Foundation

protocol LLMClient: Sendable {
    func sendMessage(history: [Message], tools: [any Tool]) async throws -> Message
}
