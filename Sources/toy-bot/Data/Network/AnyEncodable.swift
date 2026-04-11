struct AnyEncodable: Encodable, @unchecked Sendable {
    private let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let dict as [String: Any]:
            try container.encode(dict.mapValues(AnyEncodable.init))
        case let arr as [Any]:
            try container.encode(arr.map(AnyEncodable.init))
        case let str as String:
            try container.encode(str)
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        default:
            try container.encodeNil()
        }
    }
}
