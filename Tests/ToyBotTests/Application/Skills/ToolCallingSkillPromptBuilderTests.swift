import Foundation
import Testing
@testable import ToyBot

struct ToolCallingSkillPromptBuilderTests {
    @Test
    func returnsNilWhenNoSkillsAvailable() {
        let builder = ToolCallingSkillPromptBuilder(skillRegistry: StubSkillRegistry())
        #expect(builder.buildInjectedPrompt() == nil)
    }

    @Test
    func rendersSkillsWithExamplesAndTruncation() {
        let longPrompt = String(repeating: "P", count: 2_000)
        let longExample = String(repeating: "E", count: 500)
        let skill = Skill(
            metadata: .init(id: "skill-1", name: "Skill One", description: "Desc"),
            systemPrompt: longPrompt,
            examples: [
                .init(userMessage: longExample, assistantResponse: longExample),
                .init(userMessage: "u2", assistantResponse: "a2"),
                .init(userMessage: "u3", assistantResponse: "a3"),
            ],
            outputFormat: .json
        )
        let registry = StubSkillRegistry(
            metadata: [skill.metadata],
            skillsById: ["skill-1": skill]
        )
        let builder = ToolCallingSkillPromptBuilder(skillRegistry: registry)

        let prompt = builder.buildInjectedPrompt()

        #expect(prompt?.contains("SKILLS (tool-calling mode)") == true)
        #expect(prompt?.contains("[skill-1] Skill One") == true)
        #expect(prompt?.contains("Output format: json") == true)
        #expect(prompt?.contains("… [truncated]") == true)
        #expect(prompt?.contains("u3") == false) // max 2 examples
    }

    @Test
    func truncateReturnsOriginalWhenWithinLimit() {
        let builder = ToolCallingSkillPromptBuilder(skillRegistry: StubSkillRegistry())
        #expect(builder.truncate("abc", maxChars: 5) == "abc")
    }
}
