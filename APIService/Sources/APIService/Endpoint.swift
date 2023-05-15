import Foundation

public protocol URLRequestConvertible {
    var urlRequest: URLRequest? { get }
}

public protocol Endpoint: URLRequestConvertible {
    var base: String { get }
    var path: String { get }
    var urlString: String? { get }
    var headers: [String: Any]? { get }
    var queryItems: [String: Any]? { get }
    var urlRequest: URLRequest? { get }
}

public extension Endpoint {
    var urlString: String? { nil }
    var headers: [String: Any]? { nil }
    var queryItems: [String: Any]? { nil }
}

public extension Endpoint {
    private var urlComponents: URLComponents? {
        var components: URLComponents?
        
        if let urlString {
            components = URLComponents(string: urlString)
        } else {
            components = URLComponents(string: base)
            components?.path = path
        }
        
        guard var components else { return nil }
        
        if let queryItems {
            components.queryItems = queryItems.compactMap { name, value in
                return URLQueryItem(name: name, value: "\(value)")
            }
        }
        
        return components
    }
    
    var urlRequest: URLRequest? {
        guard let url = urlComponents?.url else { return nil }
        var request = URLRequest(url: url)
        
        headers?.forEach { (key, value) in
            if let value = value as? String {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
}
