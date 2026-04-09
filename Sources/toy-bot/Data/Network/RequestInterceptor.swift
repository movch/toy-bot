import Foundation

protocol RequestInterceptor: Sendable {
    func intercept(
        _ request: URLRequest,
        endpoint: Endpoint
    ) throws -> URLRequest
}

protocol TokenProvider: Sendable {
    var token: String? { get }
}

enum AuthInterceptorError: Error {
    case missingToken
}

struct AuthInterceptor: RequestInterceptor {
    let tokenProvider: TokenProvider

    func intercept(
        _ request: URLRequest,
        endpoint: Endpoint
    ) throws -> URLRequest {
        var request = request
        switch endpoint.authType {
        case .none:
            return request
        case .bearer:
            guard let token = tokenProvider.token, !token.isEmpty else {
                throw AuthInterceptorError.missingToken
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }
}
