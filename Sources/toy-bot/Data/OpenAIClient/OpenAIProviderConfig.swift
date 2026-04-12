import Foundation

struct OpenAIProviderConfig: ServerConfiguration, TokenProvider {
    let baseURL: String
    let defaultModel: String
    let token: String?
    let routingMode: RoutingMode
}
