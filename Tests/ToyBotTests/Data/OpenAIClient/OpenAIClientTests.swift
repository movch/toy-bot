import Foundation
import Testing
@testable import ToyBot

struct OpenAIClientTests {
    @Test
    func wrapsRequestBuilderErrors() async {
        let config = OpenAIProviderConfig(
            baseURL: "https://exa mple.com",
            defaultModel: "m",
            token: nil,
            routingMode: .intentRouter
        )
        let http = StubHttpClient(queued: [])
        let decoder = StubResponseDecoder(next: OpenAIChatDTO.Response(choices: []))
        let sut = OpenAIClient(providerConfig: config, httpClient: http, decoder: decoder)

        do {
            _ = try await sut.sendMessage(
                history: [.user(content: "hi")],
                tools: [],
                profile: .balanced,
                structuredOutput: .none
            )
            Issue.record("Expected failedToBuildRequest")
        } catch OpenAIClientError.failedToBuildRequest {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func throwsEmptyResponseWhenNoChoices() async {
        let config = OpenAIProviderConfig(
            baseURL: "https://example.com",
            defaultModel: "m",
            token: nil,
            routingMode: .intentRouter
        )
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let http = StubHttpClient(queued: [.success((data: Data(), response: response))])
        let decoder = StubResponseDecoder(next: OpenAIChatDTO.Response(choices: []))
        let sut = OpenAIClient(providerConfig: config, httpClient: http, decoder: decoder)

        do {
            _ = try await sut.sendMessage(
                history: [.user(content: "hi")],
                tools: [],
                profile: .balanced,
                structuredOutput: .none
            )
            Issue.record("Expected emptyResponse")
        } catch OpenAIClientError.emptyResponse {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func buildsChatRequestAndReturnsFirstMessage() async throws {
        let config = OpenAIProviderConfig(
            baseURL: "https://example.com",
            defaultModel: "m",
            token: "secret",
            routingMode: .toolCalling
        )
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let http = StubHttpClient(queued: [.success((data: Data("{}".utf8), response: response))])
        let decoder = StubResponseDecoder(
            next: OpenAIChatDTO.Response(
                choices: [.init(message: .init(role: .assistant, content: "ok", toolCalls: nil, toolCallId: nil))]
            )
        )
        let sut = OpenAIClient(providerConfig: config, httpClient: http, decoder: decoder)

        let message = try await sut.sendMessage(
            history: [.user(content: "hi")],
            tools: [],
            profile: .balanced,
            structuredOutput: .intentRouter
        )

        #expect(message.content == "ok")
        let requests = await http.requests
        #expect(requests.count == 1)
        #expect(requests[0].url?.absoluteString == "https://example.com/v1/chat/completions")
        #expect(requests[0].value(forHTTPHeaderField: "Authorization") == "Bearer secret")
        #expect(requests[0].httpMethod == "POST")

        let body = try #require(requests[0].httpBody)
        let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let responseFormat = try #require(object["response_format"] as? [String: Any])
        #expect(responseFormat["type"] as? String == "json_schema")
    }
}
