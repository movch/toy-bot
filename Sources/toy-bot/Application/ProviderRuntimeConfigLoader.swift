import Foundation

enum ProviderKind: String, Sendable {
    case openai
    case ollama
}

struct ProviderRuntimeConfigLoader {
    func load(
        arguments: [String] = CommandLine.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> OpenAIProviderConfig {
        let cli = parseCLI(arguments: arguments)

        let provider = ProviderKind(rawValue: (cli["provider"] ?? environment["TOYBOT_PROVIDER"] ?? "ollama").lowercased()) ?? .ollama

        let baseURL: String
        let model: String
        let token: String?

        switch provider {
        case .ollama:
            baseURL = cli["base-url"]
                ?? environment["TOYBOT_BASE_URL"]
                ?? cli["ollama-host"]
                ?? environment["OLLAMA_HOST"]
                ?? "http://localhost:11434"
            model = cli["model"] ?? environment["TOYBOT_MODEL"] ?? "llama3.2"
            token = cli["token"] ?? environment["TOYBOT_API_TOKEN"]
        case .openai:
            baseURL = cli["base-url"] ?? environment["TOYBOT_BASE_URL"] ?? "https://api.openai.com"
            model = cli["model"] ?? environment["TOYBOT_MODEL"] ?? "gpt-4o-mini"
            token = cli["token"] ?? environment["TOYBOT_API_TOKEN"] ?? environment["OPENAI_API_KEY"]
        }

        return OpenAIProviderConfig(
            baseURL: baseURL,
            defaultModel: model,
            token: token
        )
    }

    private func parseCLI(arguments: [String]) -> [String: String] {
        guard arguments.count > 1 else { return [:] }

        var result: [String: String] = [:]
        var index = 1
        while index < arguments.count {
            let key = arguments[index]
            guard key.hasPrefix("--"), index + 1 < arguments.count else {
                index += 1
                continue
            }
            result[String(key.dropFirst(2))] = arguments[index + 1]
            index += 2
        }
        return result
    }
}
