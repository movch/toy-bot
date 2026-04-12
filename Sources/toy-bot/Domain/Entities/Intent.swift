enum Intent: Sendable, Equatable {
    case readFile(path: String)
    case bash(command: String)
    case searchFile(keyword: String)
    case directChat
}

extension Intent {
    var label: String {
        switch self {
        case .readFile(let path):     return "read_file(\(path))"
        case .bash(let command):      return "bash(\(command))"
        case .searchFile(let keyword): return "search_file(\(keyword))"
        case .directChat:             return "direct_chat"
        }
    }
}
