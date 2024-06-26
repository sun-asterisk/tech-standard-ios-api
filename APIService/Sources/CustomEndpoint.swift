import Foundation

/// Represents a custom endpoint that can override properties of another endpoint.
public struct CustomEndpoint: Endpoint {
    /// The base URL of the endpoint.
    public var base: String? {
        if case let .base(value) = overrides {
            return value
        }
        return endpoint.base
    }

    /// The path of the endpoint.
    public var path: String? {
        if case let .path(value) = overrides {
            return value
        }
        return endpoint.path
    }

    /// The full URL string of the endpoint.
    public var urlString: String? {
        if case let .urlString(value) = overrides {
            return value
        }
        return endpoint.urlString
    }

    /// The headers for the endpoint.
    public var headers: [String: Any]? {
        if case let .headers(value) = overrides {
            return value
        }
        return endpoint.headers
    }

    /// The query items for the endpoint.
    public var queryItems: [String: Any]? {
        if case let .queryItems(value) = overrides {
            return value
        }
        return endpoint.queryItems
    }

    /// The URL request for the endpoint.
    public var urlRequest: URLRequest? { endpoint.urlRequest }

    private let endpoint: Endpoint
    private let overrides: OverrideOptions

    /// Initializes a new custom endpoint with specified endpoint and override options.
    ///
    /// - Parameters:
    ///   - endpoint: The base endpoint to override.
    ///   - overrides: The override options to apply.
    public init(endpoint: Endpoint, overrides: OverrideOptions) {
        self.endpoint = endpoint
        self.overrides = overrides
    }
}

/// Represents options for overriding properties of an endpoint.
public enum OverrideOptions {
    case base(String)
    case path(String)
    case urlString(String)
    case headers([String: Any])
    case queryItems([String: Any])
}

public extension Endpoint {
    /// Adds a base URL to the endpoint.
    ///
    /// - Parameter base: The base URL to add.
    /// - Returns: A new endpoint with the base URL added.
    func add(base: String) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .base(base))
    }

    /// Adds a base URL to the endpoint using a closure.
    ///
    /// - Parameter base: A closure that returns the base URL to add.
    /// - Returns: A new endpoint with the base URL added.
    func add(base: (Self) -> String) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .base(base(self)))
    }

    /// Adds a path to the endpoint.
    ///
    /// - Parameter path: The path to add.
    /// - Returns: A new endpoint with the path added.
    func add(path: String) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .path(path))
    }

    /// Adds a path to the endpoint using a closure.
    ///
    /// - Parameter path: A closure that returns the path to add.
    /// - Returns: A new endpoint with the path added.
    func add(path: (Self) -> String) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .path(path(self)))
    }

    /// Adds a full URL string to the endpoint.
    ///
    /// - Parameter urlString: The URL string to add.
    /// - Returns: A new endpoint with the URL string added.
    func add(urlString: String) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .urlString(urlString))
    }

    /// Adds a full URL string to the endpoint using a closure.
    ///
    /// - Parameter urlString: A closure that returns the URL string to add.
    /// - Returns: A new endpoint with the URL string added.
    func add(urlString: (Self) -> String) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .urlString(urlString(self)))
    }

    /// Adds headers to the endpoint.
    ///
    /// - Parameter headers: The headers to add.
    /// - Returns: A new endpoint with the headers added.
    func add(headers: [String: Any]) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .headers(headers))
    }

    /// Adds headers to the endpoint using a closure.
    ///
    /// - Parameter headers: A closure that returns the headers to add.
    /// - Returns: A new endpoint with the headers added.
    func add(headers: (Self) -> [String: Any]) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .headers(headers(self)))
    }

    /// Adds headers to the endpoint by merging with existing headers.
    ///
    /// - Parameter headersToMerge: The headers to merge with existing headers.
    /// - Returns: A new endpoint with the merged headers.
    func add(headersToMerge: [String: Any]) -> Endpoint {
        let mergedHeader: [String: Any]
        
        if let currentHeaders = self.headers {
            mergedHeader = mergeDictionaries(currentHeaders, headersToMerge)
        } else {
            mergedHeader = headersToMerge
        }
        
        return CustomEndpoint(endpoint: self, overrides: .headers(mergedHeader))
    }

    /// Merges two dictionaries.
    ///
    /// - Parameters:
    ///   - dict1: The first dictionary.
    ///   - dict2: The second dictionary.
    /// - Returns: A merged dictionary containing keys and values from both dictionaries.
    private func mergeDictionaries<K, V>(_ dict1: [K: V], _ dict2: [K: V]) -> [K: V] {
        var mergedDict = dict1
        
        for (key, value) in dict2 {
            mergedDict[key] = value
        }
        
        return mergedDict
    }

    /// Adds query items to the endpoint.
    ///
    /// - Parameter queryItems: The query items to add.
    /// - Returns: A new endpoint with the query items added.
    func add(queryItems: [String: Any]) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .queryItems(queryItems))
    }

    /// Adds query items to the endpoint using a closure.
    ///
    /// - Parameter queryItems: A closure that returns the query items to add.
    /// - Returns: A new endpoint with the query items added.
    func add(queryItems: (Self) -> [String: Any]) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .queryItems(queryItems(self)))
    }
}
