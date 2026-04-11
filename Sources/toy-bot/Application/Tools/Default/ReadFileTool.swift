import Foundation

struct ReadFileTool: Tool {
    private struct Arguments: Decodable {
        let path: String
    }

    let name = "read_file"
    let description = "Read UTF-8 text from one file. Requires an exact path. If the user did not give a concrete path, use bash to discover it first, then read that path."
    let parametersSchema = """
        {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Exact path to one file. If the user only described which file in words, run bash to resolve the path first, then pass it here."
                }
            },
            "required": ["path"]
        }
        """

    func execute(toolArguments: String) async throws -> String {
        guard let args = try? JSONDecoder().decode(Arguments.self, from: Data(toolArguments.utf8)) else {
            return "Error: invalid arguments for read_file. Expected JSON with a string field \"path\"."
        }

        let path = args.path
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
            return "Error: not a file (path is a directory): \(path)"
        }

        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch CocoaError.fileNoSuchFile, CocoaError.fileReadNoSuchFile {
            let hint = Self.directoryListingHint(maxEntries: 40)
            return """
                Error: File not found: \(path)
                Do not invent a path. Copy the path exactly from bash (ls/find). Common mistake: an extra leading dot so the basename no longer matches the listing.
                Current directory file names (hint, not exhaustive): \(hint)
                """
        } catch {
            return "Error reading file: \(error.localizedDescription)"
        }
    }

    private static func directoryListingHint(maxEntries: Int) -> String {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: fm.currentDirectoryPath) else {
            return "(unavailable)"
        }
        let sorted = names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        if sorted.isEmpty { return "(empty)" }
        let shown = sorted.prefix(maxEntries)
        let suffix = sorted.count > maxEntries ? " … (+\(sorted.count - maxEntries) more)" : ""
        return shown.joined(separator: ", ") + suffix
    }
}
