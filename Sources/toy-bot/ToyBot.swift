import Foundation
import Darwin

@main
struct ToyBot {
    static func main() async {
        if let oneShotPrompt = parseOneShotPrompt(arguments: CommandLine.arguments) {
            await runOneShot(prompt: oneShotPrompt)
            return
        }

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

    private static func runOneShot(prompt: String) async {
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

        do {
            let response = try await agentSession.chat(prompt)
            print(response.content)
        } catch {
            FileHandle.standardError.write(
                Data((ErrorFormatter.userMessage(for: error) + "\n").utf8)
            )
            exit(1)
        }
    }

    private static func parseOneShotPrompt(arguments: [String]) -> String? {
        var index = 1
        while index < arguments.count {
            let key = arguments[index]
            if key == "-c" || key == "--prompt" {
                guard index + 1 < arguments.count else { return nil }
                return arguments[index + 1]
            }
            index += 1
        }
        return nil
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
