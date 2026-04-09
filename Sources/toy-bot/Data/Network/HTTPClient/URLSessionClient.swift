import Foundation

final class URLSessionHttpClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
}

extension URLSessionHttpClient: HttpClient {
    func request(_ urlRequest: URLRequest) async throws -> ResponseData {
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HttpClientError.invalidResponse
        }

        return ResponseData(data: data, response: httpResponse)
    }
}
