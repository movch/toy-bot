import Foundation

typealias ResponseData = (data: Data, response: HTTPURLResponse)

enum HttpClientError: Error {
    case invalidResponse
    case invalidStatusCode(Int, Data?)
}

protocol HttpClient: Sendable {
    func request(_ urlRequest: URLRequest) async throws -> ResponseData
}
