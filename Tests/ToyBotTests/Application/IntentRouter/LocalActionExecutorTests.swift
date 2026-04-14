import Foundation
import Testing
@testable import ToyBot

struct LocalActionExecutorTests {
    @Test
    func executesReadFileIntentViaToolRegistry() async throws {
        let readTool = StubTool(name: "read_file") { args in
            let data = try #require(args.data(using: .utf8))
            let payload = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
            #expect(payload["path"] == "/tmp/file.txt")
            return "file-content"
        }
        let executor = LocalActionExecutor(toolRegistry: ToolRegistry(tools: [readTool]))

        let result = try await executor.execute(intent: .readFile(path: "/tmp/file.txt"))
        #expect(result == "file-content")
    }

    @Test
    func searchFileIntentBuildsFindCommand() async throws {
        let bashTool = StubTool(name: "bash") { args in
            #expect(args.contains("find . -iname '*ToyBot*'"))
            #expect(args.contains("-maxdepth 8"))
            return "ok"
        }
        let executor = LocalActionExecutor(toolRegistry: ToolRegistry(tools: [bashTool]))

        let result = try await executor.execute(intent: .searchFile(keyword: "ToyBot"))
        #expect(result == "ok")
    }

    @Test
    func directChatAndSkillReturnEmptyString() async throws {
        let executor = LocalActionExecutor(toolRegistry: ToolRegistry(tools: []))

        let direct = try await executor.execute(intent: .directChat)
        let skill = try await executor.execute(intent: .skill(id: "x"))

        #expect(direct.isEmpty)
        #expect(skill.isEmpty)
    }

    @Test
    func returnsToolNotFoundErrorMessage() async throws {
        let executor = LocalActionExecutor(toolRegistry: ToolRegistry(tools: []))

        let result = try await executor.execute(intent: .bash(command: "ls"))
        #expect(result.contains("tool \"bash\" is not registered"))
    }
}
