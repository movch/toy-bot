import Foundation

@main
struct ToyBot {
    static func main() async {
        let providerConfig = ProviderRuntimeConfigLoader().load()
        let httpClient = URLSessionHttpClient(session: .shared)
        let decoder = JSONResponseDecoder(jsonDecoder: JSONDecoder())
        let llmClient = OpenAIClient(
            providerConfig: providerConfig,
            httpClient: httpClient,
            decoder: decoder
        )
        let agent = ChatAgent(llmClient: llmClient, systemPrompt: Constants.defaultAgentPrompt)
        let agentSession = InMemoryAgentSession(agent: agent)
        let chatLoop = ChatLoop(agentSession: agentSession)

        print("toy-bot is configured for baseURL: \(providerConfig.baseURL)")
        print("model: \(providerConfig.defaultModel)")
        
        await chatLoop.runChatLoop()
    }
}
