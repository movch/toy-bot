protocol Tool: Sendable {
    var name: String { get }
    var description: String { get }
    var parametersSchema: String { get }

    func execute(toolArguments: String) async throws -> String
}
