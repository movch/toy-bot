import Foundation

struct ReadFileTool: Tool {
    private struct Arguments: Decodable {
        let path: String
    }
    
    let name = "read_file"
    let description = "Read the contents of a text file at the given path"
    let parametersSchema = """
        {
            "type": "object",
            "properties": {
                "path": { "type": "string", "description": "Path to the file to read" }
            },
            "required": ["path"]
        }
        """
    
    func execute(toolArguments: String) async throws -> String {
        guard let args = try? JSONDecoder().decode(Arguments.self, from: Data(toolArguments.utf8)) else {
            return "Error: invalid arguments for read_file. Expected JSON with a 'path' string field."
        }

        do {
            return try String(contentsOfFile: args.path, encoding: .utf8)
        } catch CocoaError.fileNoSuchFile, CocoaError.fileReadNoSuchFile {
            let filename = URL(fileURLWithPath: args.path).lastPathComponent
            return "Error: file not found at '\(args.path)'. Use bash with `find . -name \"\(filename)\" 2>/dev/null` to locate it, then call read_file again with the correct full path."
        } catch {
            return "Error reading '\(args.path)': \(error.localizedDescription)"
        }
    }
}
