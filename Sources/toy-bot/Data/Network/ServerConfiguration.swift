import Foundation

protocol ServerConfiguration: Sendable {
    var baseURL: String { get }
}
