enum Intent: Sendable, Equatable {
    case readFile(path: String)
    case bash(command: String)
    case searchFile(keyword: String)
    case directChat
    case skill(id: String)
}

extension Intent {
    var label: String {
        switch self {
        case .readFile(let path):      return "read_file(\(path))"
        case .bash(let command):       return "bash(\(command))"
        case .searchFile(let keyword): return "search_file(\(keyword))"
        case .directChat:              return "direct_chat"
        case .skill(let id):           return "skill(\(id))"
        }
    }

    /// Same tool intent with equivalent arguments (trimmed), used to detect routing loops.
    func isDuplicateLoop(with other: Intent) -> Bool {
        switch (self, other) {
        case (.directChat, .directChat):
            return true
        case (.readFile(let a), .readFile(let b)):
            return a.trimmingCharacters(in: .whitespacesAndNewlines)
                == b.trimmingCharacters(in: .whitespacesAndNewlines)
        case (.bash(let a), .bash(let b)):
            return a.trimmingCharacters(in: .whitespacesAndNewlines)
                == b.trimmingCharacters(in: .whitespacesAndNewlines)
        case (.searchFile(let a), .searchFile(let b)):
            return a.trimmingCharacters(in: .whitespacesAndNewlines)
                == b.trimmingCharacters(in: .whitespacesAndNewlines)
        case (.skill(let a), .skill(let b)):
            return a == b
        default:
            return false
        }
    }
}
