extension Message {
    var openAIChatDTO: OpenAIChatDTO.Message {
        switch self {
        case .system(let content):    return OpenAIChatDTO.Message(role: .system, content: content)
        case .user(let content):      return OpenAIChatDTO.Message(role: .user, content: content)
        case .assistant(let content): return OpenAIChatDTO.Message(role: .assistant, content: content)
        }
    }
}

extension OpenAIChatDTO.Message {
    var domain: Message {
        switch role {
        case .system:    return .system(content)
        case .user:      return .user(content)
        case .assistant: return .assistant(content)
        }
    }
}
