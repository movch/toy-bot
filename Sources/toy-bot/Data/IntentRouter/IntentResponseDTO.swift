struct IntentResponseDTO: Decodable {
    let action: String
    let path: String?
    let command: String?
    let keyword: String?

    func toIntent() -> Intent {
        switch action {
        case "read_file":
            guard let path else { return .directChat }
            return .readFile(path: path)
        case "bash":
            guard let command else { return .directChat }
            return .bash(command: command)
        case "search_file":
            guard let keyword else { return .directChat }
            return .searchFile(keyword: keyword)
        default:
            return .directChat
        }
    }
}
