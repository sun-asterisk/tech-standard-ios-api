import Foundation

/// A concrete implementation of the `Endpoint` protocol.
public struct BaseEndpoint: Endpoint {
    public var base: String?
    public var path: String?
    public var urlString: String?
    public var httpMethod = HttpMethod.get
    public var headers: [String: Any]?
    public var queryItems: [String: Any]?
    public var body: [String: Any]?
    public var bodyData: Data?
    public var parts: [MultipartFormData]
    
    /// Initializes a new BaseEndpoint.
    ///
    /// - Parameters:
    ///   - base: The base URL string.
    ///   - path: The path component of the URL.
    ///   - urlString: The full URL string.
    ///   - httpMethod: The HTTP method to use.
    ///   - headers: The headers to include in the request.
    ///   - queryItems: The query items to include in the URL.
    ///   - body: The body parameters to include in the request.
    ///   - bodyData: The raw body data to include in the request.
    ///   - parts: The multipart form data parts to include in the request.
    public init(base: String? = nil,
                path: String? = nil,
                urlString: String? = nil,
                httpMethod: HttpMethod = HttpMethod.get,
                headers: [String : Any]? = nil,
                queryItems: [String : Any]? = nil,
                body: [String : Any]? = nil,
                bodyData: Data? = nil,
                parts: [MultipartFormData] = []
    ) {
        self.base = base
        self.path = path
        self.urlString = urlString
        self.httpMethod = httpMethod
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.bodyData = bodyData
        self.parts = parts
    }
}

public protocol EndpointConvertible {
    /// Converts the conforming type to a BaseEndpoint.
    ///
    /// - Returns: A new BaseEndpoint.
    func toEndpoint() -> BaseEndpoint
}

extension String: EndpointConvertible {
    /// Converts a String to a BaseEndpoint.
    ///
    /// - Returns: A new BaseEndpoint with the URL string set to the string value.
    public func toEndpoint() -> BaseEndpoint {
        BaseEndpoint(urlString: self)
    }
}

extension URL: EndpointConvertible {
    /// Converts a URL to a BaseEndpoint.
    ///
    /// - Returns: A new BaseEndpoint with the URL string set to the absolute string value of the URL.
    public func toEndpoint() -> BaseEndpoint {
        BaseEndpoint(urlString: self.absoluteString)
    }
}

extension URLRequest: EndpointConvertible {
    /// Converts a URLRequest to a BaseEndpoint.
    ///
    /// - Returns: A new BaseEndpoint with properties set from the URLRequest.
    public func toEndpoint() -> BaseEndpoint {
        return BaseEndpoint(
            base: nil,
            path: nil,
            urlString: self.url?.absoluteString,
            httpMethod: HttpMethod(rawValue: self.httpMethod ?? "") ?? .get,
            headers: self.allHTTPHeaderFields,
            queryItems: nil,
            body: nil,
            bodyData: self.httpBody
        )
    }
}
