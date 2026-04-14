import Foundation

@main
struct ToyBot {
    static func main() async {
        let providerConfig = ProviderRuntimeConfigLoader().load()
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 300
        sessionConfig.timeoutIntervalForResource = 300
        let httpClient = URLSessionHttpClient(session: URLSession(configuration: sessionConfig))
        let decoder = JSONResponseDecoder(jsonDecoder: JSONDecoder())
        
        let llmClient = OpenAIClient(
            providerConfig: providerConfig,
            httpClient: httpClient,
            decoder: decoder
        )
        
        let toolRegistry = ToolRegistry(tools: [
            ReadFileTool(),
            BashTool(),
        ])

        let skillRegistry = MarkdownSkillLoader(skillsDirectory: resolveSkillsDirectory())

        let agentSession: any AgentSession

        switch providerConfig.routingMode {
        case .intentRouter:
            agentSession = IntentRoutedSession(
                router: LLMIntentRouter(llmClient: llmClient, skillRegistry: skillRegistry),
                executor: LocalActionExecutor(toolRegistry: toolRegistry),
                synthesizer: LLMSynthesizer(llmClient: llmClient),
                skillExecutor: SkillExecutor(llmClient: llmClient, skillRegistry: skillRegistry),
                systemPrompt: Constants.defaultAgentPrompt
            )
        case .toolCalling:
            let injectedSkillsPrompt = ToolCallingSkillPromptBuilder(skillRegistry: skillRegistry)
                .buildInjectedPrompt() ?? ""
            let toolCallingSystemPrompt = Constants.defaultAgentPrompt + injectedSkillsPrompt
            agentSession = InMemoryAgentSession(
                agent: ChatAgent(
                    llmClient: llmClient,
                    systemPrompt: toolCallingSystemPrompt,
                    toolRegistry: toolRegistry
                )
            )
        }

        let chatLoop = ChatLoop(agentSession: agentSession)

        let skillCount = skillRegistry.metadata.count
        print("\ntoy-bot is configured for baseURL: \(providerConfig.baseURL)")
        print("model: \(providerConfig.defaultModel)")
        print("routing: \(providerConfig.routingMode.rawValue)")
        print("skills: \(skillCount == 0 ? "none" : skillCount.description)")
        
        await chatLoop.runChatLoop()
    }

    private static func resolveSkillsDirectory() -> String {
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath
        let path = (cwd as NSString).appendingPathComponent("skills")
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
            return path
        }
        // Return the path regardless — MarkdownSkillLoader handles missing directory gracefully.
        return path
    }
}
