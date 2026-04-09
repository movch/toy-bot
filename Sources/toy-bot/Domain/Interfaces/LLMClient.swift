import Foundation

protocol LLMClient {
    func sendMessage(history: [Message]) async throws -> Message
}
