struct Skill: Sendable {
    struct Metadata: Sendable {
        let id: String
        let name: String
        let description: String
    }

    struct Example: Sendable {
        let userMessage: String
        let assistantResponse: String
    }

    enum OutputFormat: String, Sendable {
        case freeText = "free_text"
        case json = "json"
    }

    let metadata: Metadata
    let systemPrompt: String
    let examples: [Example]
    let outputFormat: OutputFormat
}
