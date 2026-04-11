enum OpenAIChatDTO {
    struct Request: Encodable, Sendable {
        let model: String
        let messages: [Message]
        let temperature: Double?
        let topP: Double?
        let tools: [ToolSchema]?

        enum CodingKeys: String, CodingKey {
            case model, messages, temperature, tools
            case topP = "top_p"
        }
    }

    struct Response: Decodable, Sendable {
        struct Choice: Decodable, Sendable {
            let message: Message
        }

        let choices: [Choice]
    }

    struct Message: Codable, Sendable {
        let role: Role
        let content: String?
        let toolCalls: [ToolCallDTO]?
        let toolCallId: String?

        enum CodingKeys: String, CodingKey {
            case role, content
            case toolCalls = "tool_calls"
            case toolCallId = "tool_call_id"
        }
    }

    enum Role: String, Codable, Sendable {
        case system
        case user
        case assistant
        case tool
    }

    struct ToolSchema: Encodable, Sendable {
        let type: String
        let function: FunctionSchema
    }

    struct FunctionSchema: Encodable, Sendable {
        let name: String
        let description: String
        let parameters: [String: AnyEncodable]
    }

    struct ToolCallDTO: Codable, Sendable {
        let id: String
        let type: String
        let function: FunctionCallDTO
    }

    struct FunctionCallDTO: Codable, Sendable {
        let name: String
        let arguments: String
    }
}
