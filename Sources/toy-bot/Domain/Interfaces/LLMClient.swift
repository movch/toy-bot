import Foundation

protocol LLMClient: Sendable {
    func sendMessage(history: [Message], tools: [any Tool], profile: GenerationProfile) async throws -> Message
}
