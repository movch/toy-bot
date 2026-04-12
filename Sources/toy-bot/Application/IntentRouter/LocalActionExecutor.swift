import Foundation

struct LocalActionExecutor: ActionExecutor {
    private let toolRegistry: ToolRegistry

    init(toolRegistry: ToolRegistry) {
        self.toolRegistry = toolRegistry
    }

    func execute(intent: Intent) async throws -> String {
        switch intent {
        case .readFile(let path):
            return await run("read_file", arguments: ["path": path])

        case .bash(let command):
            return await run("bash", arguments: ["command": command])

        case .searchFile(let keyword):
            let command = "find . -iname '*\(keyword)*' -not -path '*/.git/*' -maxdepth 8 2>/dev/null | head -20"
            return await run("bash", arguments: ["command": command])

        case .directChat:
            return ""
        }
    }
}

// MARK: - Private

private extension LocalActionExecutor {
    func run(_ toolName: String, arguments: [String: String]) async -> String {
        guard let json = try? JSONEncoder().encode(arguments),
              let jsonString = String(data: json, encoding: .utf8)
        else {
            return "Error: failed to encode arguments for \(toolName)."
        }

        do {
            return try await toolRegistry.execute(name: toolName, toolArguments: jsonString)
        } catch let error as ToolRegistryError {
            switch error {
            case .toolNotFound(let name):
                return "Error: tool \"\(name)\" is not registered."
            }
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
}
