import Foundation

final class JSONResponseDecoder {
    let jsonDecoder: JSONDecoder
    
    init(jsonDecoder: JSONDecoder) {
        self.jsonDecoder = jsonDecoder
    }
}

extension JSONResponseDecoder: ResponseDecoder {
    func map<T>(_ responseData: ResponseData) throws -> T where T : Decodable {
        guard (200...299).contains(responseData.response.statusCode) else {
            throw HttpClientError.invalidStatusCode(
                responseData.response.statusCode,
                responseData.data
            )
        }
        
        return try jsonDecoder.decode(T.self, from: responseData.data)
    }
}
