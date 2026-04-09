protocol ResponseDecoder: Sendable {
    func map<T: Decodable>(_ responseData: ResponseData) throws -> T
}
