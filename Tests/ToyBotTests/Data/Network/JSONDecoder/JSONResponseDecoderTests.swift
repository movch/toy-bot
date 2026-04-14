import Foundation
import Testing
@testable import ToyBot

private struct DecodablePayload: Decodable, Equatable {
    let value: String
}

struct JSONResponseDecoderTests {
    @Test
    func decodesPayloadFor2xxResponse() throws {
        let decoder = JSONResponseDecoder(jsonDecoder: JSONDecoder())
        let data = Data(#"{"value":"ok"}"#.utf8)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let output: DecodablePayload = try decoder.map((data: data, response: response))
        #expect(output == DecodablePayload(value: "ok"))
    }

    @Test
    func throwsInvalidStatusCodeForNon2xx() {
        let decoder = JSONResponseDecoder(jsonDecoder: JSONDecoder())
        let data = Data("bad".utf8)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!

        do {
            let _: DecodablePayload = try decoder.map((data: data, response: response))
            Issue.record("Expected invalidStatusCode")
        } catch HttpClientError.invalidStatusCode(let code, let body) {
            #expect(code == 500)
            #expect(body == data)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
