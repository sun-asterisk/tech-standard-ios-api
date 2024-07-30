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
    
    /// The http method for the endpoint.
    public var httpMethod: HttpMethod {
        if case let .httpMethod(value) = overrides {
            return value
        }
        return endpoint.httpMethod
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
    
    /// The body for the endpoint.
    public var body: [String: Any]? {
        if case let .body(value) = overrides {
            return value
        }
        return endpoint.body
    }
    
    /// The raw body data of the endpoint.
    public var bodyData: Data? {
        if case let .bodyData(value) = overrides {
            return value
        }
        return endpoint.bodyData
    }
    
    /// The multipart form data parts of the endpoint.
    /// Returns the overridden parts if set, otherwise returns the parts of the base endpoint.
    public var parts: [MultipartFormData] {
        if case let .parts(value) = overrides {
            return value
        }
        return endpoint.parts
    }

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
    case base(String?)
    case path(String?)
    case urlString(String?)
    case httpMethod(HttpMethod)
    case headers([String: Any]?)
    case queryItems([String: Any]?)
    case body([String: Any]?)
    case bodyData(Data?)
    case parts([MultipartFormData])
}

public extension Endpoint {
    /// Adds a base URL to the endpoint.
    ///
    /// - Parameter base: The base URL to add.
    /// - Returns: A new endpoint with the base URL added.
    func add(base: String?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .base(base))
    }

    /// Adds a base URL to the endpoint using a closure.
    ///
    /// - Parameter base: A closure that returns the base URL to add.
    /// - Returns: A new endpoint with the base URL added.
    func add(base: (Self) -> String?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .base(base(self)))
    }

    /// Adds a path to the endpoint.
    ///
    /// - Parameter path: The path to add.
    /// - Returns: A new endpoint with the path added.
    func add(path: String?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .path(path))
    }

    /// Adds a path to the endpoint using a closure.
    ///
    /// - Parameter path: A closure that returns the path to add.
    /// - Returns: A new endpoint with the path added.
    func add(path: (Self) -> String?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .path(path(self)))
    }

    /// Adds a full URL string to the endpoint.
    ///
    /// - Parameter urlString: The URL string to add.
    /// - Returns: A new endpoint with the URL string added.
    func add(urlString: String?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .urlString(urlString))
    }

    /// Adds a full URL string to the endpoint using a closure.
    ///
    /// - Parameter urlString: A closure that returns the URL string to add.
    /// - Returns: A new endpoint with the URL string added.
    func add(urlString: (Self) -> String?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .urlString(urlString(self)))
    }
    
    /// Adds an HTTP method to the endpoint.
    ///
    /// - Parameter httpMethod: The HTTP method to add.
    /// - Returns: A new endpoint with the HTTP method added.
    func add(httpMethod: HttpMethod) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .httpMethod(httpMethod))
    }

    /// Adds an HTTP method to the endpoint using a closure.
    ///
    /// - Parameter httpMethod: A closure that returns the HTTP method to add.
    /// - Returns: A new endpoint with the HTTP method added.
    func add(httpMethod: (Self) -> HttpMethod) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .httpMethod(httpMethod(self)))
    }

    /// Adds headers to the endpoint.
    ///
    /// - Parameter headers: The headers to add.
    /// - Returns: A new endpoint with the headers added.
    func add(headers: [String: Any]?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .headers(headers))
    }

    /// Adds headers to the endpoint using a closure.
    ///
    /// - Parameter headers: A closure that returns the headers to add.
    /// - Returns: A new endpoint with the headers added.
    func add(headers: (Self) -> [String: Any]?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .headers(headers(self)))
    }

    /// Adds headers to the endpoint by merging with existing headers.
    ///
    /// - Parameter additionalHeaders: The headers to merge with existing headers.
    /// - Returns: A new endpoint with the merged headers.
    @available(*, deprecated, message: "Use append(headers:) instead")
    func add(additionalHeaders: [String: Any]) -> Endpoint {
        let newHeaders: [String: Any]
        
        if let currentHeaders = self.headers {
            newHeaders = mergeDictionaries(currentHeaders, additionalHeaders)
        } else {
            newHeaders = additionalHeaders
        }
        
        return CustomEndpoint(endpoint: self, overrides: .headers(newHeaders))
    }
    
    /// Appends headers to the existing headers of the endpoint.
    ///
    /// - Parameter headers: The headers to append.
    /// - Returns: A new endpoint with the appended headers.
    func append(headers: [String: Any]) -> Endpoint {
        let newHeaders: [String: Any]
        
        if let currentHeaders = self.headers {
            newHeaders = mergeDictionaries(currentHeaders, headers)
        } else {
            newHeaders = headers
        }
        
        return CustomEndpoint(endpoint: self, overrides: .headers(newHeaders))
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
    func add(queryItems: [String: Any]?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .queryItems(queryItems))
    }

    /// Adds query items to the endpoint using a closure.
    ///
    /// - Parameter queryItems: A closure that returns the query items to add.
    /// - Returns: A new endpoint with the query items added.
    func add(queryItems: (Self) -> [String: Any]?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .queryItems(queryItems(self)))
    }
    
    /// Adds a body to the endpoint.
    ///
    /// - Parameter body: The body to add as a dictionary.
    /// - Returns: A new endpoint with the body added.
    func add(body: [String: Any]?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .body(body))
    }

    /// Adds a body to the endpoint using a closure.
    ///
    /// - Parameter body: A closure that returns the body to add as a dictionary.
    /// - Returns: A new endpoint with the body added.
    func add(body: (Self) -> [String: Any]?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .body(body(self)))
    }

    /// Adds raw body data to the endpoint.
    ///
    /// - Parameter bodyData: The raw body data to add.
    /// - Returns: A new endpoint with the raw body data added.
    func add(bodyData: Data?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .bodyData(bodyData))
    }

    /// Adds raw body data to the endpoint using a closure.
    ///
    /// - Parameter bodyData: A closure that returns the raw body data to add.
    /// - Returns: A new endpoint with the raw body data added.
    func add(bodyData: (Self) -> Data?) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .bodyData(bodyData(self)))
    }
    
    /// Adds multipart form data parts to the endpoint.
    ///
    /// - Parameter parts: The multipart form data parts to add.
    /// - Returns: A new endpoint with the multipart form data parts added.
    func add(parts: [MultipartFormData]) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .parts(parts))
    }

    /// Adds multipart form data parts to the endpoint using a closure.
    ///
    /// - Parameter parts: A closure that returns the multipart form data parts to add.
    /// - Returns: A new endpoint with the multipart form data parts added.
    func add(parts: (Self) -> [MultipartFormData]) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .parts(parts(self)))
    }

    /// Appends multipart form data parts to the existing parts of the endpoint.
    ///
    /// - Parameter parts: The multipart form data parts to append.
    /// - Returns: A new endpoint with the appended multipart form data parts.
    func append(parts: [MultipartFormData]) -> Endpoint {
        CustomEndpoint(endpoint: self, overrides: .parts(self.parts + parts))
    }

    /// Configures the endpoint for a multipart form-data request.
    ///
    /// - Parameter boundary: The boundary string for the multipart form-data. Defaults to a UUID string.
    /// - Returns: A new endpoint configured for multipart form-data with the appropriate headers and body.
    func multipart(boundary: String = "Boundary-\(UUID().uuidString)") -> Endpoint {
        let endpoint = append(headers: [
            "Content-Type": "multipart/form-data; boundary=" + boundary
        ])
        
        return endpoint.addMultipartBody(boundary: boundary)
    }
    
    private func addMultipartBody(boundary: String) -> Endpoint {
        var bodyData = Data()

        if let parameters = body {
            for (key, value) in parameters {
                bodyData.append("--\(boundary)\r\n")
                bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                bodyData.append("\(value)\r\n")
            }
        }

        for part in self.parts {
            bodyData.append("--\(boundary)\r\n")
            
            if let fileName = part.fileName {
                bodyData.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(fileName)\"\r\n")
            } else {
                bodyData.append("Content-Disposition: form-data; name=\"files\"\r\n\r\n")
            }
            
            if let mimeType = part.mimeType {
                bodyData.append("Content-Type: \(mimeType)\r\n\r\n")
            }
            
            if case let MultipartFormData.Provider.data(data) = part.provider {
                bodyData.append(data)
            }
            
            bodyData.append("\r\n")
        }

        bodyData.append("--\(boundary)--\r\n")
        return self.add(bodyData: bodyData)
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

// MARK: - Helpers
public extension Endpoint {
    /// Adds Basic Authorization headers to the endpoint.
    ///
    /// - Parameters:
    ///   - username: The username to include in the Basic Authorization.
    ///   - password: The password to include in the Basic Authorization.
    /// - Returns: A new endpoint with the Basic Authorization header added.
    func add(username: String, password: String) -> Endpoint {
        let loginString = "\(username):\(password)"
        
        guard let loginData = loginString.data(using: .utf8) else {
            return self
        }
        
        let base64LoginString = loginData.base64EncodedString()
        
        return add(additionalHeaders: [
            "Authorization": "Basic \(base64LoginString)"
        ])
    }
}

extension CustomEndpoint: EndpointConvertible {
    /// Converts the current endpoint to a BaseEndpoint instance.
    ///
    /// - Returns: A new BaseEndpoint with the properties copied from the current endpoint.
    public func toEndpoint() -> BaseEndpoint {
        BaseEndpoint(
            base: base,
            path: path,
            urlString: urlString,
            httpMethod: httpMethod,
            headers: headers,
            queryItems: queryItems,
            body: body,
            bodyData: bodyData
        )
    }
}
