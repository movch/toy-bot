import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum AuthType: Sendable {
    case none
    case bearer
}

protocol Endpoint {
    var method: HTTPMethod { get }
    var path: String { get }
    var headers: [String: String] { get }
    var urlParams: [String: any CustomStringConvertible] { get }
    var body: Data? { get }
    var authType: AuthType { get }
}

