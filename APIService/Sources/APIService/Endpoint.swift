import Foundation
import Combine

public protocol URLRequestConvertible {
    var urlRequest: URLRequest? { get }
}

public protocol Endpoint: URLRequestConvertible {
    var base: String? { get }
    var path: String? { get }
    var urlString: String? { get }
    var headers: [String: Any]? { get }
    var queryItems: [String: Any]? { get }
}

public extension Endpoint {
    var base: String? { nil }
    var path: String? { nil }
    var urlString: String? { nil }
    var headers: [String: Any]? { nil }
    var queryItems: [String: Any]? { nil }
}

public extension Endpoint {
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
    
    var urlRequest: URLRequest? {
        guard let url = urlComponents?.url else { return nil }
        var request = URLRequest(url: url)
        
        headers?
            .compactMapValues { $0 as? String }
            .forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        return request
    }
    
    var publisher: AnyPublisher<Endpoint, Never> {
        Just(self).eraseToAnyPublisher()
    }
}
