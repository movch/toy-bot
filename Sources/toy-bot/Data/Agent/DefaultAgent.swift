import Foundation

struct DefaultAgent: Sendable, Agent {
    let llmClient: LLMClient
    let systemPrompt: String
}
