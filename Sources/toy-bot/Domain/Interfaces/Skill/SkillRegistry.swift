protocol SkillRegistry: Sendable {
    /// Lightweight metadata for all available skills.
    /// Does not load skill prompts or examples.
    var metadata: [Skill.Metadata] { get }

    /// Loads the full skill (prompt + examples) by id.
    /// Called only when the router has selected a specific skill.
    func loadSkill(id: String) throws -> Skill
}

enum SkillRegistryError: Error {
    case skillNotFound(String)
    case invalidSkillFile(String, reason: String)
}
