import Foundation

final class MarkdownSkillLoader: SkillRegistry, @unchecked Sendable {
    private let skillsDirectory: String
    private var _metadata: [Skill.Metadata]?

    init(skillsDirectory: String) {
        self.skillsDirectory = skillsDirectory
    }

    var metadata: [Skill.Metadata] {
        if let cached = _metadata { return cached }
        let loaded = discoverMetadata()
        _metadata = loaded
        return loaded
    }

    func loadSkill(id: String) throws -> Skill {
        let path = skillPath(id: id)
        guard FileManager.default.fileExists(atPath: path) else {
            throw SkillRegistryError.skillNotFound(id)
        }
        let content: String
        do {
            content = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw SkillRegistryError.invalidSkillFile(id, reason: error.localizedDescription)
        }
        return try parseSkill(id: id, content: content)
    }
}

// MARK: - Discovery

private extension MarkdownSkillLoader {

    func discoverMetadata() -> [Skill.Metadata] {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: skillsDirectory) else {
            return []
        }
        return files
            .filter { $0.hasSuffix(".md") }
            .sorted()
            .compactMap { filename in
                let path = skillsDirectory + "/" + filename
                guard let content = try? String(contentsOfFile: path, encoding: .utf8),
                      let front = parseFrontMatter(content)
                else { return nil }
                let inferredId = String(filename.dropLast(".md".count))
                return Skill.Metadata(
                    id: front["id"] ?? inferredId,
                    name: front["name"] ?? inferredId,
                    description: front["description"] ?? ""
                )
            }
    }

    func skillPath(id: String) -> String {
        skillsDirectory + "/" + id + ".md"
    }
}

// MARK: - Parsing

private extension MarkdownSkillLoader {

    func parseSkill(id: String, content: String) throws -> Skill {
        guard let front = parseFrontMatter(content) else {
            throw SkillRegistryError.invalidSkillFile(id, reason: "missing YAML front-matter (expected --- block at top)")
        }

        let body = extractBody(content)
        let (systemPrompt, examples) = splitExamples(from: body)

        let outputFormat = front["output_format"]
            .flatMap(Skill.OutputFormat.init(rawValue:)) ?? .freeText

        return Skill(
            metadata: Skill.Metadata(
                id: front["id"] ?? id,
                name: front["name"] ?? id,
                description: front["description"] ?? ""
            ),
            systemPrompt: systemPrompt,
            examples: examples,
            outputFormat: outputFormat
        )
    }

    /// Parses `---\nkey: value\n---` front-matter into a dictionary.
    func parseFrontMatter(_ content: String) -> [String: String]? {
        let lines = content.components(separatedBy: .newlines)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return nil }

        var result: [String: String] = [:]
        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "---" { break }
            let parts = trimmed.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }
            result[String(parts[0]).trimmingCharacters(in: .whitespaces)] =
                String(parts[1]).trimmingCharacters(in: .whitespaces)
        }
        return result.isEmpty ? nil : result
    }

    /// Returns everything after the closing `---` of the front-matter block.
    func extractBody(_ content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        var fenceCount = 0
        var bodyStart = 0
        for (i, line) in lines.enumerated() {
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                fenceCount += 1
                if fenceCount == 2 { bodyStart = i + 1; break }
            }
        }
        return lines.dropFirst(bodyStart).joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Splits body into (systemPrompt, examples) on the `---examples---` separator.
    func splitExamples(from body: String) -> (String, [Skill.Example]) {
        let separator = "---examples---"
        guard let range = body.range(of: separator) else {
            return (body, [])
        }
        let prompt = String(body[..<range.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let examplesText = String(body[range.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (prompt, parseExamples(examplesText))
    }

    /// Parses `user: ...\nassistant: ...` pairs from the examples section.
    func parseExamples(_ text: String) -> [Skill.Example] {
        var examples: [Skill.Example] = []
        var currentRole: String?
        var currentLines: [String] = []
        var pendingUser: String?

        func flush() {
            guard currentRole == "assistant", let user = pendingUser else { return }
            let response = currentLines.joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !user.isEmpty, !response.isEmpty {
                examples.append(Skill.Example(userMessage: user, assistantResponse: response))
            }
            pendingUser = nil
        }

        for line in text.components(separatedBy: .newlines) {
            if line.hasPrefix("user:") {
                flush()
                if currentRole == "user" {
                    pendingUser = currentLines.joined(separator: "\n")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                currentRole = "user"
                currentLines = [String(line.dropFirst("user:".count))]
            } else if line.hasPrefix("assistant:") {
                if currentRole == "user" {
                    pendingUser = currentLines.joined(separator: "\n")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                currentRole = "assistant"
                currentLines = [String(line.dropFirst("assistant:".count))]
            } else {
                currentLines.append(line)
            }
        }
        flush()
        return examples
    }
}
