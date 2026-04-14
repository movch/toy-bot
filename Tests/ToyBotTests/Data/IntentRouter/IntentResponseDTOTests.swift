import Testing
@testable import ToyBot

struct IntentResponseDTOTests {
    @Test
    func readFileTrimsPath() {
        let dto = IntentResponseDTO(
            action: "read_file",
            path: " Sources/toy-bot/ToyBot.swift ",
            command: nil,
            keyword: nil,
            skillId: nil,
            reasoning: nil
        )
        #expect(dto.toIntent() == .readFile(path: "Sources/toy-bot/ToyBot.swift"))
    }

    @Test
    func blankFieldsFallbackToDirectChat() {
        let bash = IntentResponseDTO(
            action: "bash",
            path: nil,
            command: " \n ",
            keyword: nil,
            skillId: nil,
            reasoning: nil
        )
        let search = IntentResponseDTO(
            action: "search_file",
            path: nil,
            command: nil,
            keyword: nil,
            skillId: nil,
            reasoning: nil
        )
        let skill = IntentResponseDTO(
            action: "skill",
            path: nil,
            command: nil,
            keyword: nil,
            skillId: " ",
            reasoning: nil
        )

        #expect(bash.toIntent() == .directChat)
        #expect(search.toIntent() == .directChat)
        #expect(skill.toIntent() == .directChat)
    }

    @Test
    func unknownActionFallsBackToDirectChat() {
        let dto = IntentResponseDTO(
            action: "unknown",
            path: "/tmp/a",
            command: "ls",
            keyword: "x",
            skillId: "y",
            reasoning: nil
        )
        #expect(dto.toIntent() == .directChat)
    }
}
