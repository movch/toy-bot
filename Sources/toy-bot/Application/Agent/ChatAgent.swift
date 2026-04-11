import Foundation

struct ChatAgent: Sendable, Agent {
    let llmClient: LLMClient
    let systemPrompt: String
    let toolRegistry: ToolRegistry
}
