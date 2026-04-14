import Foundation

/// Builds additional system prompt content for tool-calling mode.
/// This path is intended for larger models: all skills are injected
/// directly into the system prompt instead of being routed/executed separately.
struct ToolCallingSkillPromptBuilder {
    private let skillRegistry: any SkillRegistry
    private let maxPromptChars = 12_000
    private let maxPromptPerSkillChars = 1_600
    private let maxExamplesPerSkill = 2
    private let maxExampleChars = 400

    init(skillRegistry: any SkillRegistry) {
        self.skillRegistry = skillRegistry
    }

    func buildInjectedPrompt() -> String? {
        let loadedSkills = skillRegistry.metadata.compactMap { metadata in
            try? skillRegistry.loadSkill(id: metadata.id)
        }
        guard !loadedSkills.isEmpty else { return nil }

        var blocks: [String] = []
        var usedChars = 0
        for skill in loadedSkills {
            let block = renderSkill(skill)
            if usedChars + block.count > maxPromptChars { break }
            blocks.append(block)
            usedChars += block.count
        }
        guard !blocks.isEmpty else { return nil }
        let skillsBlock = blocks.joined(separator: "\n\n")

        return """

        ---
        SKILLS (tool-calling mode)
        - Use these skills as task-specific behavior modules when relevant.
        - Prefer these instructions for formatting/generation tasks before using generic behavior.
        - If multiple skills match, choose the one with the most specific description.

        \(skillsBlock)
        ---
        """
    }

    private func renderSkill(_ skill: Skill) -> String {
        let trimmedPrompt = truncate(skill.systemPrompt, maxChars: maxPromptPerSkillChars)
        var block = """
        [\(skill.metadata.id)] \(skill.metadata.name)
        Description: \(skill.metadata.description)
        Output format: \(skill.outputFormat.rawValue)
        Prompt:
        \(trimmedPrompt)
        """

        if !skill.examples.isEmpty {
            let examples = skill.examples.prefix(maxExamplesPerSkill).map { example in
                """
                - user: \(truncate(example.userMessage, maxChars: maxExampleChars))
                  assistant: \(truncate(example.assistantResponse, maxChars: maxExampleChars))
                """
            }.joined(separator: "\n")
            block += "\nExamples:\n\(examples)"
        }

        return block
    }

    func truncate(_ text: String, maxChars: Int) -> String {
        guard text.count > maxChars else { return text }
        return String(text.prefix(maxChars)) + "… [truncated]"
    }
}
