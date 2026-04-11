enum Message: Sendable {
    case system(content: String)
    case user(content: String)
    case assistant(content: String, toolCalls: [ToolCall])
    case tool(content: String, toolCallId: String)
}

extension Message {
    var content: String {
        switch self {
        case .system(let content),
             .user(let content),
             .assistant(let content, _),
             .tool(let content, _):
            return content
        }
    }
}
