import Foundation

enum OpenAIChatDTOMapper {
    static func makeRequest(
        model: String,
        history: [Message],
        temperature: Double?
    ) -> OpenAIChatDTO.Request {
        OpenAIChatDTO.Request(
            model: model,
            messages: history.map(toDTO),
            temperature: temperature
        )
    }

    static func firstMessage(from response: OpenAIChatDTO.Response) -> Message? {
        response.choices.first.map { toDomain($0.message) }
    }

    private static func toDTO(_ message: Message) -> OpenAIChatDTO.Message {
        OpenAIChatDTO.Message(
            role: toDTO(message.role),
            content: message.content
        )
    }

    private static func toDomain(_ message: OpenAIChatDTO.Message) -> Message {
        Message(
            role: toDomain(message.role),
            content: message.content
        )
    }

    private static func toDTO(_ role: Role) -> OpenAIChatDTO.Role {
        switch role {
        case .system: return .system
        case .user: return .user
        case .assistant: return .assistant
        }
    }

    private static func toDomain(_ role: OpenAIChatDTO.Role) -> Role {
        switch role {
        case .system: return .system
        case .user: return .user
        case .assistant: return .assistant
        }
    }
}
