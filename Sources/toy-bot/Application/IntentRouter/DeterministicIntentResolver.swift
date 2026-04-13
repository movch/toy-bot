import Foundation

/// Infers the next intent deterministically from the last intent and its execution result.
/// Returns `nil` when the next step is ambiguous and should be delegated to the LLM router.
struct DeterministicIntentResolver {

    /// Attempt to resolve the next intent without calling the LLM.
    func resolve(after intent: Intent, result: String) -> Intent? {
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)

        switch intent {
        case .searchFile:
            return resolveAfterSearch(output: trimmed)

        case .readFile:
            return resolveAfterRead(output: trimmed)

        case .bash:
            return resolveAfterBash(output: trimmed)

        case .directChat, .skill:
            return nil
        }
    }
}

// MARK: - Per-intent resolution

private extension DeterministicIntentResolver {

    func resolveAfterSearch(output: String) -> Intent? {
        guard !output.isEmpty, !output.lowercased().hasPrefix("error") else {
            return nil
        }

        let paths = extractFilePaths(from: output)

        switch paths.count {
        case 1:
            return .readFile(path: paths[0])
        case 2...5:
            let best = paths.first { isLikelyBestMatch($0) } ?? paths[0]
            return .readFile(path: best)
        default:
            return nil
        }
    }

    func resolveAfterRead(output: String) -> Intent? {
        guard !output.isEmpty, !output.lowercased().hasPrefix("error") else {
            return nil
        }
        return .directChat
    }

    func resolveAfterBash(output: String) -> Intent? {
        guard !output.isEmpty, !output.lowercased().hasPrefix("error") else {
            return nil
        }

        let paths = extractFilePaths(from: output)
        if paths.count == 1 {
            return .readFile(path: paths[0])
        }
        return nil
    }
}

// MARK: - Helpers

private extension DeterministicIntentResolver {

    func extractFilePaths(from output: String) -> [String] {
        output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { line in
                guard !line.isEmpty else { return false }
                let lower = line.lowercased()
                if lower.hasPrefix("error") || lower.hasPrefix("warning") { return false }
                return line.contains("/") || line.contains(".")
            }
    }

    /// Prefer paths that are shallower in the directory tree.
    func isLikelyBestMatch(_ path: String) -> Bool {
        path.components(separatedBy: "/").count <= 3
    }
}
