import Foundation

enum RequestBuilderError: Error {
    case invalidURL
}

struct RequestBuilder: Sendable {
    private let interceptors: [any RequestInterceptor]

    init(interceptors: [any RequestInterceptor] = []) {
        self.interceptors = interceptors
    }

    func buildRequest(
        endpoint: Endpoint,
        serverConfiguration: ServerConfiguration
    ) throws -> URLRequest {
        guard var components = URLComponents(string: serverConfiguration.baseURL + endpoint.path) else {
            throw RequestBuilderError.invalidURL
        }

        if !endpoint.urlParams.isEmpty {
            components.queryItems = endpoint.urlParams.map {
                URLQueryItem(name: $0.key, value: $0.value.description)
            }
        }

        guard let url = components.url else {
            throw RequestBuilderError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.allHTTPHeaderFields = endpoint.headers

        for interceptor in interceptors {
            request = try interceptor.intercept(request, endpoint: endpoint)
        }

        return request
    }
}
