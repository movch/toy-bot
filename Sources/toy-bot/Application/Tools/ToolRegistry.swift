enum ToolRegistryError: Error {
    case toolNotFound(String)
}

final class ToolRegistry: Sendable {
    private let tools: [String: any Tool]
    
    var allTools: [any Tool] {
        Array(tools.values)
    }
    
    init(tools: [any Tool]) {
        self.tools = Dictionary(uniqueKeysWithValues: tools.map { ($0.name, $0) })
    }
    
    func execute(name: String, toolArguments: String) async throws -> String {
        guard let tool = tools[name] else {
            throw ToolRegistryError.toolNotFound(name)
        }
        
        return try await tool.execute(toolArguments: toolArguments)
    }
}
