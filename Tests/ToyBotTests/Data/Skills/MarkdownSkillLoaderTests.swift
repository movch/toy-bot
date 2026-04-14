import Foundation
import Testing
@testable import ToyBot

struct MarkdownSkillLoaderTests {
    @Test
    func metadataReturnsEmptyForMissingDirectory() {
        let loader = MarkdownSkillLoader(skillsDirectory: "/tmp/does-not-exist-\(UUID().uuidString)")
        #expect(loader.metadata.isEmpty)
    }

    @Test
    func metadataReadsAndCachesMarkdownFiles() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        try write(
            """
            ---
            id: summarize
            name: Summarize
            description: Summarize code
            ---
            Prompt
            """,
            to: tempDir + "/summarize.md"
        )
        try write(
            """
            ---
            name: Explain
            description: Explain code
            ---
            Prompt
            """,
            to: tempDir + "/explain.md"
        )
        try write("not markdown", to: tempDir + "/note.txt")

        let loader = MarkdownSkillLoader(skillsDirectory: tempDir)
        let first = loader.metadata
        try write(
            """
            ---
            id: late
            name: Late
            description: Added later
            ---
            Prompt
            """,
            to: tempDir + "/late.md"
        )
        let second = loader.metadata

        #expect(first.count == 2)
        #expect(second.count == 2)
        #expect(first.map(\.id).sorted() == ["explain", "summarize"])
    }

    @Test
    func loadSkillParsesPromptExamplesAndOutputFormat() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        try write(
            """
            ---
            id: review
            name: Review
            description: Review PR
            output_format: json
            ---
            You are a strict reviewer.
            ---examples---
            user: find issues
            assistant: issue one
            user: summarize
            assistant: summary
            """,
            to: tempDir + "/review.md"
        )

        let loader = MarkdownSkillLoader(skillsDirectory: tempDir)
        let skill = try loader.loadSkill(id: "review")

        #expect(skill.metadata.id == "review")
        #expect(skill.metadata.name == "Review")
        #expect(skill.outputFormat == .json)
        #expect(skill.systemPrompt == "You are a strict reviewer.")
        #expect(skill.examples.count == 2)
        #expect(skill.examples[0].userMessage.contains("find issues"))
        #expect(skill.examples[0].assistantResponse.contains("issue one"))
    }

    @Test
    func loadSkillThrowsForMissingOrInvalidSkill() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        try write("no front matter", to: tempDir + "/broken.md")
        let loader = MarkdownSkillLoader(skillsDirectory: tempDir)

        do {
            _ = try loader.loadSkill(id: "missing")
            Issue.record("Expected skillNotFound")
        } catch SkillRegistryError.skillNotFound(let id) {
            #expect(id == "missing")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        do {
            _ = try loader.loadSkill(id: "broken")
            Issue.record("Expected invalidSkillFile")
        } catch SkillRegistryError.invalidSkillFile(let id, _) {
            #expect(id == "broken")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private func makeTempDir() throws -> String {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("toy-bot-tests-\(UUID().uuidString)")
            .path
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }

    private func write(_ content: String, to path: String) throws {
        try content.write(toFile: path, atomically: true, encoding: .utf8)
    }
}
