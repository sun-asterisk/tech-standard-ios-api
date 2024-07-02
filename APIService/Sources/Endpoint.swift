import Foundation

/// Protocol that defines a type that can be converted to a URLRequest.
public protocol URLRequestConvertible {
    var urlRequest: URLRequest? { get }
}

/// Enumeration of HTTP methods.
public enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// Protocol that defines the properties of an endpoint.
public protocol Endpoint: URLRequestConvertible {
    var base: String? { get }
    var path: String? { get }
    var urlString: String? { get }
    var httpMethod: HttpMethod { get }
    var headers: [String: Any]? { get }
    var queryItems: [String: Any]? { get }
    var body: [String: Any]? { get }
}

public extension Endpoint {
    var base: String? { nil }
    var path: String? { nil }
    var urlString: String? { nil }
    var httpMethod: HttpMethod { .get }
    var headers: [String: Any]? { nil }
    var queryItems: [String: Any]? { nil }
    var body: [String: Any]? { nil }
}

public extension Endpoint {
    /// Constructs URLComponents from the endpoint's properties.
    private var urlComponents: URLComponents? {
        var components: URLComponents?
        
        if let urlString {
            components = URLComponents(string: urlString)
        } else if let base, let path {
            components = URLComponents(string: base)
            components?.path = path
        }
        
        guard var components else { return nil }
        
        if let queryItems {
            components.queryItems = queryItems.compactMap { URLQueryItem(name: $0, value: "\($1)") }
        }
        
        return components
    }
    
    /// Constructs a URLRequest from the endpoint's properties.
    var urlRequest: URLRequest? {
        guard let url = urlComponents?.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        
        if let body,
            let jsonData = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted) {
            request.httpBody = jsonData
        }
        
        headers?
            .compactMapValues { $0 as? String }
            .forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        return request
    }
}
