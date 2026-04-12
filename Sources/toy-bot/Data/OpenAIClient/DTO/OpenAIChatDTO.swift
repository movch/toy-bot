enum OpenAIChatDTO {
    /// OpenAI `response_format` (also accepted by Ollama `/v1/chat/completions` for structured outputs).
    struct ResponseFormat: Encodable, Sendable {
        let type: String
        let jsonSchema: JSONSchemaBody?

        enum CodingKeys: String, CodingKey {
            case type
            case jsonSchema = "json_schema"
        }

        static func jsonObject() -> ResponseFormat {
            ResponseFormat(type: "json_object", jsonSchema: nil)
        }

        static func jsonSchema(name: String, strict: Bool, schema: [String: Any]) -> ResponseFormat {
            ResponseFormat(
                type: "json_schema",
                jsonSchema: JSONSchemaBody(name: name, strict: strict, schema: AnyEncodable(schema))
            )
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            if let jsonSchema {
                try container.encode(jsonSchema, forKey: .jsonSchema)
            }
        }
    }

    struct JSONSchemaBody: Encodable, Sendable {
        let name: String
        let strict: Bool
        let schema: AnyEncodable
    }

    struct Request: Encodable, Sendable {
        let model: String
        let messages: [Message]
        let temperature: Double?
        let topP: Double?
        let tools: [ToolSchema]?
        let responseFormat: ResponseFormat?

        enum CodingKeys: String, CodingKey {
            case model, messages, temperature, tools
            case topP = "top_p"
            case responseFormat = "response_format"
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
