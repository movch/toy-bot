import Foundation

struct BashTool: Tool {
    private struct Arguments: Decodable {
        let command: String
    }
    
    let name = "bash"
    let description = "Run one shell command; stdout and stderr are returned. Use for discovery when the path is unknown: list, search, glob, then pass a path from output to read_file."
    let parametersSchema = """
        {
            "type": "object",
            "properties": {
                "command": {
                    "type": "string",
                    "description": "Single bash command. When the user did not give an exact path, discover candidates first (list, find, glob), then use a printed path in read_file."
                }
            },
            "required": ["command"]
        }
        """
    
    func execute(toolArguments: String) async throws -> String {
        guard let args = try? JSONDecoder().decode(Arguments.self, from: Data(toolArguments.utf8)) else {
            return "Error: invalid arguments. Expected JSON with a 'command' string field. Try again."
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
