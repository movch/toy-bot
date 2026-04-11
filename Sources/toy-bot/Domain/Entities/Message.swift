enum Message: Sendable {
    case system(String)
    case user(String)
    case assistant(String)
}

extension Message {
    var content: String {
        switch self {
        case .system(let content), .user(let content), .assistant(let content):
            return content
        }
    }
}
