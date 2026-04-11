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
        
        let agent = ChatAgent(
            llmClient: llmClient,
            systemPrompt: Constants.defaultAgentPrompt,
            toolRegistry: toolRegistry
        )
        
        let agentSession = InMemoryAgentSession(agent: agent)
        let chatLoop = ChatLoop(agentSession: agentSession)

        print("\ntoy-bot is configured for baseURL: \(providerConfig.baseURL)")
        print("model: \(providerConfig.defaultModel)")
        
        await chatLoop.runChatLoop()
    }
}
