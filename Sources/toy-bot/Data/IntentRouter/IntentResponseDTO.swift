struct IntentResponseDTO: Decodable {
    let action: String
    let path: String?
    let command: String?
    let keyword: String?
    let skillId: String?
    let reasoning: String?

    enum CodingKeys: String, CodingKey {
        case action, path, command, keyword, reasoning
        case skillId = "skill_id"
    }

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
                    "enum": ["read_file", "bash", "search_file", "direct_chat", "skill"],
                ],
                "path": nullableString,
                "command": nullableString,
                "keyword": nullableString,
                "skill_id": nullableString,
                "reasoning": nullableString,
            ],
            "required": ["action", "path", "command", "keyword", "skill_id", "reasoning"],
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
        case "skill":
            guard let skillId else { return .directChat }
            let trimmed = skillId.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return .directChat }
            return .skill(id: trimmed)
        default:
            return .directChat
        }
    }
}
