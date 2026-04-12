import Foundation

struct LLMIntentRouter: IntentRouter {
    private let llmClient: LLMClient
    private let maxClassificationAttempts = 3

    init(llmClient: LLMClient) {
        self.llmClient = llmClient
    }

    func classify(history: [Message]) async throws -> Intent {
        var messages: [Message] = [.system(content: Constants.intentRouterPrompt)] + history

        for attempt in 0..<maxClassificationAttempts {
            let response = try await llmClient.sendMessage(
                history: messages,
                tools: [],
                profile: .deterministic,
                structuredOutput: .intentRouter
            )

            let raw = response.content.strippingMarkdownFences()

            if let data = raw.data(using: .utf8),
               let dto = try? JSONDecoder().decode(IntentResponseDTO.self, from: data) {
                return dto.toIntent()
            }

            if attempt < maxClassificationAttempts - 1 {
                messages.append(.user(content: Constants.intentRouterSelfCorrectionUserMessage))
            }
        }

        return .directChat
    }
}

// MARK: - String helper

private extension String {
    func strippingMarkdownFences() -> String {
        var result = trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            result = result
                .components(separatedBy: "\n")
                .dropFirst()
                .joined(separator: "\n")
        }
        if result.hasSuffix("```") {
            result = result
                .components(separatedBy: "\n")
                .dropLast()
                .joined(separator: "\n")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
