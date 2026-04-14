import Foundation
import Testing
@testable import ToyBot

struct ReadFileToolTests {
    @Test
    func returnsValidationErrorForInvalidArguments() async throws {
        let tool = ReadFileTool()
        let result = try await tool.execute(toolArguments: "{}")
        #expect(result.contains("invalid arguments for read_file"))
    }

    @Test
    func readsUtf8FileContent() async throws {
        let tool = ReadFileTool()
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("toy-bot-read-file-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: tempFile) }
        try "hello".write(to: tempFile, atomically: true, encoding: .utf8)

        let result = try await tool.execute(toolArguments: #"{"path":"\#(tempFile.path)"}"#)
        #expect(result == "hello")
    }

    @Test
    func returnsDirectoryErrorForDirectoryPath() async throws {
        let tool = ReadFileTool()
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("toy-bot-read-dir-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let result = try await tool.execute(toolArguments: #"{"path":"\#(tempDir.path)"}"#)
        #expect(result.contains("path is a directory"))
    }

    @Test
    func returnsFileNotFoundGuidanceForMissingPath() async throws {
        let tool = ReadFileTool()
        let missingPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("toy-bot-missing-\(UUID().uuidString).txt")
            .path

        let result = try await tool.execute(toolArguments: #"{"path":"\#(missingPath)"}"#)
        #expect(result.contains("Error: File not found"))
        #expect(result.contains("Do not invent a path"))
        #expect(result.contains("Current directory file names"))
    }

    @Test
    func returnsReadErrorForNonUtf8File() async throws {
        let tool = ReadFileTool()
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("toy-bot-binary-\(UUID().uuidString).bin")
        defer { try? FileManager.default.removeItem(at: tempFile) }
        try Data([0xFF, 0xD8, 0xFF]).write(to: tempFile)

        let result = try await tool.execute(toolArguments: #"{"path":"\#(tempFile.path)"}"#)
        #expect(result.contains("Error reading file"))
    }
}
