import Foundation

/// Protocol that defines a type that can be converted to a URLRequest.
public protocol URLRequestConvertible {
    var urlRequest: URLRequest? { get }
}

// Conforming URLRequest to URLRequestConvertible protocol
extension URLRequest: URLRequestConvertible {
    /// Returns self as URLRequest.
    public var urlRequest: URLRequest? { self }
}

// Conforming URL to URLRequestConvertible protocol
extension URL: URLRequestConvertible {
    /// Converts URL to URLRequest.
    public var urlRequest: URLRequest? { URLRequest(url: self) }
}

// Conforming String to URLRequestConvertible protocol
extension String: URLRequestConvertible {
    /// Converts String to URLRequest if the string can be converted to a valid URL.
    public var urlRequest: URLRequest? {
        guard let url = URL(string: self) else { return nil }
        return URLRequest(url: url)
    }
}
