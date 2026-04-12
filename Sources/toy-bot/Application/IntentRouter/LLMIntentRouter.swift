import Foundation

struct LLMIntentRouter: IntentRouter {
    private let llmClient: LLMClient

    init(llmClient: LLMClient) {
        self.llmClient = llmClient
    }

    func classify(history: [Message]) async throws -> Intent {
        let routerHistory: [Message] = [.system(content: Constants.intentRouterPrompt)] + history

        let response = try await llmClient.sendMessage(
            history: routerHistory,
            tools: [],
            profile: .deterministic,
            structuredOutput: .intentRouter
        )

        let raw = response.content.strippingMarkdownFences()

        guard let data = raw.data(using: .utf8),
              let dto = try? JSONDecoder().decode(IntentResponseDTO.self, from: data)
        else {
            return .directChat
        }

        return dto.toIntent()
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
