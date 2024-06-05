import Foundation

public struct EndpointDecorator: Endpoint {
    public var base: String? {
        if case let .base(value) = overriding {
            return value
        }
        
        return endpoint.base
    }
    
    public var path: String? {
        if case let .path(value) = overriding {
            return value
        }
        
        return endpoint.path
    }
    
    public var urlString: String? {
        if case let .urlString(value) = overriding {
            return value
        }
        
        return endpoint.urlString
    }
    
    public var headers: [String: Any]? {
        if case let .headers(value) = overriding {
            return value
        }
        
        return endpoint.headers
    }
    
    public var queryItems: [String: Any]? {
        if case let .queryItems(value) = overriding {
            return value
        }
        
        return endpoint.queryItems
    }
    
    public var urlRequest: URLRequest? { endpoint.urlRequest }
    
    private let endpoint: Endpoint
    private let overriding: OverridingProperty
    
    public init(endpoint: Endpoint, overriding: OverridingProperty) {
        self.endpoint = endpoint
        self.overriding = overriding
    }
}

public enum OverridingProperty {
    case base(String)
    case path(String)
    case urlString(String)
    case headers([String: Any])
    case queryItems([String: Any])
}
