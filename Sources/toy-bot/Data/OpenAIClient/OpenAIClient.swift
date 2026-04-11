import Foundation

enum OpenAIClientError: Error {
    case failedToBuildRequest(underlying: Error)
    case emptyResponse
}

final class OpenAIClient: Sendable {
    private let providerConfig: OpenAIProviderConfig
    private let requestBuilder: RequestBuilder
    private let httpClient: HttpClient
    private let decoder: ResponseDecoder

    init(
        providerConfig: OpenAIProviderConfig,
        requestBuilder: RequestBuilder? = nil,
        httpClient: HttpClient,
        decoder: ResponseDecoder
    ) {
        self.providerConfig = providerConfig
        self.requestBuilder = requestBuilder ?? RequestBuilder(
            interceptors: [AuthInterceptor(tokenProvider: providerConfig)]
        )
        self.httpClient = httpClient
        self.decoder = decoder
    }
}

extension OpenAIClient: LLMClient {
    func sendMessage(history: [Message], tools: [any Tool], profile: GenerationProfile) async throws -> Message {
        let chatRequest = OpenAIChatDTO.Request(
            model: providerConfig.defaultModel,
            history: history,
            profile: profile,
            tools: tools
        )

        let endpoint = OpenAIEndpoint.chatCompletions(request: chatRequest)

        let urlRequest: URLRequest
        do {
            urlRequest = try requestBuilder.buildRequest(
                endpoint: endpoint,
                serverConfiguration: providerConfig
            )
        } catch {
            throw OpenAIClientError.failedToBuildRequest(underlying: error)
        }

        let responseData = try await httpClient.request(urlRequest)
        let chatResponse: OpenAIChatDTO.Response = try decoder.map(responseData)

        guard let message = chatResponse.firstDomainMessage else {
            throw OpenAIClientError.emptyResponse
        }

        return message
    }
}
