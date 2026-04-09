enum OpenAIChatDTO {
    struct Request: Encodable, Sendable {
        let model: String
        let messages: [Message]
        let temperature: Double?
    }

    struct Response: Decodable, Sendable {
        struct Choice: Decodable, Sendable {
            let message: Message
        }

        let choices: [Choice]
    }

    struct Message: Codable, Sendable {
        let role: Role
        let content: String
    }

    enum Role: String, Codable, Sendable {
        case system
        case user
        case assistant
    }
}
