import Testing
@testable import ToyBot

struct ProviderRuntimeConfigLoaderTests {
    private let sut = ProviderRuntimeConfigLoader()

    @Test
    func defaultsToOllamaIntentRouting() {
        let config = sut.load(arguments: ["toy-bot"], environment: [:])

        #expect(config.baseURL == "http://localhost:11434")
        #expect(config.defaultModel == "llama3.2")
        #expect(config.token == nil)
        #expect(config.routingMode == .intentRouter)
    }

    @Test
    func openAIUsesOpenAIDefaultsAndApiKeyFallback() {
        let config = sut.load(
            arguments: ["toy-bot"],
            environment: [
                "TOYBOT_PROVIDER": "openai",
                "OPENAI_API_KEY": "secret",
            ]
        )

        #expect(config.baseURL == "https://api.openai.com")
        #expect(config.defaultModel == "gpt-4o-mini")
        #expect(config.token == "secret")
        #expect(config.routingMode == .toolCalling)
    }

    @Test
    func cliOverridesEnvironmentValues() {
        let config = sut.load(
            arguments: [
                "toy-bot",
                "--provider", "openai",
                "--base-url", "http://override",
                "--model", "m1",
                "--token", "t1",
                "--routing", "intent",
            ],
            environment: [
                "TOYBOT_PROVIDER": "ollama",
                "TOYBOT_BASE_URL": "http://env",
                "TOYBOT_MODEL": "env-model",
                "TOYBOT_API_TOKEN": "env-token",
                "TOYBOT_ROUTING": "tool-calling",
            ]
        )

        #expect(config.baseURL == "http://override")
        #expect(config.defaultModel == "m1")
        #expect(config.token == "t1")
        #expect(config.routingMode == .intentRouter)
    }

    @Test
    func ollamaHostFallbackAndInvalidRoutingFallback() {
        let config = sut.load(
            arguments: ["toy-bot"],
            environment: [
                "TOYBOT_PROVIDER": "ollama",
                "OLLAMA_HOST": "http://ollama-host",
                "TOYBOT_ROUTING": "invalid",
            ]
        )

        #expect(config.baseURL == "http://ollama-host")
        #expect(config.routingMode == .intentRouter)
    }
}
