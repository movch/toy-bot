import Foundation
import Testing
@testable import ToyBot

private struct TokenProviderStub: TokenProvider {
    let token: String?
}

private struct AuthEndpointStub: Endpoint {
    let authType: AuthType
    let method: HTTPMethod = .get
    let path: String = "/"
    let headers: [String : String] = [:]
    let urlParams: [String : any CustomStringConvertible] = [:]
    let body: Data? = nil
}

struct RequestInterceptorTests {
    @Test
    func authInterceptorSkipsHeaderForNoneAuth() throws {
        let interceptor = AuthInterceptor(tokenProvider: TokenProviderStub(token: "abc"))
        let request = URLRequest(url: URL(string: "https://example.com")!)

        let result = try interceptor.intercept(request, endpoint: AuthEndpointStub(authType: .none))

        #expect(result.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test
    func authInterceptorSkipsHeaderForEmptyToken() throws {
        let interceptor = AuthInterceptor(tokenProvider: TokenProviderStub(token: ""))
        let request = URLRequest(url: URL(string: "https://example.com")!)

        let result = try interceptor.intercept(request, endpoint: AuthEndpointStub(authType: .bearer))

        #expect(result.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test
    func authInterceptorSetsBearerHeader() throws {
        let interceptor = AuthInterceptor(tokenProvider: TokenProviderStub(token: "secret"))
        let request = URLRequest(url: URL(string: "https://example.com")!)

        let result = try interceptor.intercept(request, endpoint: AuthEndpointStub(authType: .bearer))

        #expect(result.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
    }
}
