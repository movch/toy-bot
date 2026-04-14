import Foundation
import Testing
@testable import ToyBot

private struct EndpointStub: Endpoint {
    let method: HTTPMethod
    let path: String
    let headers: [String : String]
    let urlParams: [String : any CustomStringConvertible]
    let body: Data?
    let authType: AuthType
}

private struct ServerConfigStub: ServerConfiguration {
    let baseURL: String
}

private struct HeaderInterceptor: RequestInterceptor {
    let name: String
    let value: String

    func intercept(_ request: URLRequest, endpoint: Endpoint) throws -> URLRequest {
        var copy = request
        copy.setValue(value, forHTTPHeaderField: name)
        return copy
    }
}

struct RequestBuilderTests {
    @Test
    func buildsRequestWithQueryBodyHeadersAndMethod() throws {
        let endpoint = EndpointStub(
            method: .post,
            path: "/v1/items",
            headers: ["X-Test": "1"],
            urlParams: ["q": "swift", "page": 2],
            body: Data("{}".utf8),
            authType: .none
        )
        let sut = RequestBuilder()

        let request = try sut.buildRequest(
            endpoint: endpoint,
            serverConfiguration: ServerConfigStub(baseURL: "https://example.com")
        )

        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString.contains("/v1/items") == true)
        #expect(request.url?.query?.contains("q=swift") == true)
        #expect(request.url?.query?.contains("page=2") == true)
        #expect(request.value(forHTTPHeaderField: "X-Test") == "1")
        #expect(request.httpBody == Data("{}".utf8))
    }

    @Test
    func appliesInterceptorsInOrder() throws {
        let endpoint = EndpointStub(
            method: .get,
            path: "/x",
            headers: [:],
            urlParams: [:],
            body: nil,
            authType: .none
        )
        let sut = RequestBuilder(
            interceptors: [
                HeaderInterceptor(name: "X-Order", value: "first"),
                HeaderInterceptor(name: "X-Order", value: "second"),
            ]
        )

        let request = try sut.buildRequest(
            endpoint: endpoint,
            serverConfiguration: ServerConfigStub(baseURL: "https://example.com")
        )

        #expect(request.value(forHTTPHeaderField: "X-Order") == "second")
    }

    @Test
    func throwsForInvalidURL() {
        let endpoint = EndpointStub(
            method: .get,
            path: "/x",
            headers: [:],
            urlParams: [:],
            body: nil,
            authType: .none
        )
        let sut = RequestBuilder()

        do {
            _ = try sut.buildRequest(
                endpoint: endpoint,
                serverConfiguration: ServerConfigStub(baseURL: "https://exa mple.com")
            )
            Issue.record("Expected RequestBuilderError.invalidURL")
        } catch RequestBuilderError.invalidURL {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
