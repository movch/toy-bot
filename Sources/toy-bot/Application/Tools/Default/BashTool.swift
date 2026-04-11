import Foundation

struct BashTool: Tool {
    private struct Arguments: Decodable {
        let command: String
    }
    
    let name = "bash"
    let description = "Execute a bash shell command and return its output"
    let parametersSchema = """
        {
            "type": "object",
            "properties": {
                "command": { "type": "string", "description": "The bash command to execute" }
            },
            "required": ["command"]
        }
        """
    
    func execute(toolArguments: String) async throws -> String {
        guard let args = try? JSONDecoder().decode(Arguments.self, from: Data(toolArguments.utf8)) else {
            return "Error: invalid arguments"
        }
        
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", args.command]
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        return String(data: data, encoding: .utf8) ?? "Command completed with no output"
    }
}
