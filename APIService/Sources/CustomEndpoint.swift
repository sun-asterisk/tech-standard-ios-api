import Foundation

public struct CustomEndpoint: Endpoint {
    public var base: String? {
        if case let .base(value) = overrides {
            return value
        }
        
        return endpoint.base
    }
    
    public var path: String? {
        if case let .path(value) = overrides {
            return value
        }
        
        return endpoint.path
    }
    
    public var urlString: String? {
        if case let .urlString(value) = overrides {
            return value
        }
        
        return endpoint.urlString
    }
    
    public var headers: [String: Any]? {
        if case let .headers(value) = overrides {
            return value
        }
        
        return endpoint.headers
    }
    
    public var queryItems: [String: Any]? {
        if case let .queryItems(value) = overrides {
            return value
        }
        
        return endpoint.queryItems
    }
    
    public var urlRequest: URLRequest? { endpoint.urlRequest }
    
    private let endpoint: Endpoint
    private let overrides: OverrideOptions
    
    public init(endpoint: Endpoint, overrides: OverrideOptions) {
        self.endpoint = endpoint
        self.overrides = overrides
    }
}

public enum OverrideOptions {
    case base(String)
    case path(String)
    case urlString(String)
    case headers([String: Any])
    case queryItems([String: Any])
}

public extension Endpoint {
    func add(base: String) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .base(base))
    }
    
    func add(base: (Self) -> String) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .base(base(self)))
    }
    
    func add(path: String) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .path(path))
    }
    
    func add(path: (Self) -> String) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .path(path(self)))
    }
    
    func add(urlString: String) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .urlString(urlString))
    }
    
    func add(urlString: (Self) -> String) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .urlString(urlString(self)))
    }
    
    func add(headers: [String: Any]) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .headers(headers))
    }
    
    func add(headers: (Self) -> [String: Any]) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .headers(headers(self)))
    }
    
    func add(headersToMerge: [String: Any]) -> Endpoint {
        let mergedHeader: [String: Any]
        
        if let currentHeaders = self.headers {
            mergedHeader = mergeDictionaries(currentHeaders, headersToMerge)
        } else {
            mergedHeader = headersToMerge
        }
        
        return CustomEndpoint(endpoint: self, overrides: .headers(mergedHeader))
    }
    
    private func mergeDictionaries<K, V>(_ dict1: [K: V], _ dict2: [K: V]) -> [K: V] {
        var mergedDict = dict1
        
        for (key, value) in dict2 {
            mergedDict[key] = value
        }
        
        return mergedDict
    }
    
    func add(queryItems: [String: Any]) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .queryItems(queryItems))
    }
    
    func add(queryItems: (Self) -> [String: Any]) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .queryItems(queryItems(self)))
    }
}
