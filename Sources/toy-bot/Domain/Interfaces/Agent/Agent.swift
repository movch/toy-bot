protocol Agent {
    var llmClient: LLMClient { get }
    var systemPrompt: String { get }
    var toolRegistry: ToolRegistry { get }
}
