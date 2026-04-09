import Foundation

protocol LLMClient: Sendable {
    func sendMessage(history: [Message]) async throws -> Message
}
