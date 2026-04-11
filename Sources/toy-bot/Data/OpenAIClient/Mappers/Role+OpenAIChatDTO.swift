extension Role {
    var openAIChatDTO: OpenAIChatDTO.Role {
        switch self {
        case .system: return .system
        case .user: return .user
        case .assistant: return .assistant
        }
    }
}

extension OpenAIChatDTO.Role {
    var domain: Role {
        switch self {
        case .system: return .system
        case .user: return .user
        case .assistant: return .assistant
        }
    }
}
