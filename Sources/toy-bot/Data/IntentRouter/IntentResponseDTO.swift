struct IntentResponseDTO: Decodable {
    let action: String
    let path: String?
    let command: String?
    let keyword: String?
    let reasoning: String?

    /// JSON Schema for OpenAI-style `response_format` / Ollama structured outputs (`json_schema.strict`).
    static var routerJSONSchema: [String: Any] {
        let nullableString: [String: Any] = [
            "anyOf": [
                ["type": "string"],
                ["type": "null"],
            ],
        ]
        return [
            "type": "object",
            "properties": [
                "action": [
                    "type": "string",
                    "enum": ["read_file", "bash", "search_file", "direct_chat"],
                ],
                "path": nullableString,
                "command": nullableString,
                "keyword": nullableString,
                "reasoning": nullableString,
            ],
            "required": ["action", "path", "command", "keyword", "reasoning"],
            "additionalProperties": false,
        ]
    }

    func toIntent() -> Intent {
        switch action {
        case "read_file":
            guard let path else { return .directChat }
            let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return .directChat }
            return .readFile(path: trimmed)
        case "bash":
            guard let command else { return .directChat }
            let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return .directChat }
            return .bash(command: trimmed)
        case "search_file":
            guard let keyword else { return .directChat }
            let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return .directChat }
            return .searchFile(keyword: trimmed)
        default:
            return .directChat
        }
    }
}
