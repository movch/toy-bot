import Foundation

protocol LLMClient: Sendable {
    func sendMessage(
        history: [Message],
        tools: [any Tool],
        profile: GenerationProfile,
        structuredOutput: LLMStructuredOutput
    ) async throws -> Message
}

extension LLMClient {
    func sendMessage(history: [Message], tools: [any Tool], profile: GenerationProfile) async throws -> Message {
        try await sendMessage(history: history, tools: tools, profile: profile, structuredOutput: .none)
    }
}
