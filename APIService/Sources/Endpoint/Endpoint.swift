import Foundation

/// Enumeration of HTTP methods.
public enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
}

/// A structure representing multipart form data.
public struct MultipartFormData {

    /// An enumeration representing the data provider for the multipart form data.
    public enum Provider: Hashable {
        /// Provides data directly.
        case data(Data)
        
        /// Provides data from a file URL.
        case file(URL)
    }
    
    /// The data provider for the multipart form data.
    public let provider: Provider

    /// The name associated with the multipart form data.
    public let name: String
    
    /// The file name for the multipart form data, if any.
    public let fileName: String?

    /// The MIME type for the multipart form data, if any.
    public let mimeType: String?
    
    /// Initializes a new `MultipartFormData` instance.
    ///
    /// - Parameters:
    ///   - provider: The data provider for the multipart form data.
    ///   - name: The name associated with the multipart form data.
    ///   - fileName: The file name for the multipart form data, if any. Defaults to `nil`.
    ///   - mimeType: The MIME type for the multipart form data, if any. Defaults to `nil`.
    public init(provider: Provider, name: String, fileName: String? = nil, mimeType: String? = nil) {
        self.provider = provider
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
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
    var bodyData: Data? { get }
    var parts: [MultipartFormData] { get }
}

public extension Endpoint {
    var base: String? { nil }
    var path: String? { nil }
    var urlString: String? { nil }
    var httpMethod: HttpMethod { .get }
    var headers: [String: Any]? { nil }
    var queryItems: [String: Any]? { nil }
    var body: [String: Any]? { nil }
    var bodyData: Data? { nil }
    var parts: [MultipartFormData] { [] }
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
            components.queryItems = (components.queryItems ?? [])
                + queryItems.compactMap { URLQueryItem(name: $0, value: "\($1)") }
        }
        
        return components
    }
    
    /// Constructs a URLRequest from the endpoint's properties.
    var urlRequest: URLRequest? {
        guard let url = urlComponents?.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        
        if httpMethod != .get {
            if let bodyData {
                request.httpBody = bodyData
            } else if let body,
                      let jsonData = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted) {
                request.httpBody = jsonData
            }
        }
        
        headers?
            .compactMapValues { $0 as? String }
            .forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        return request
    }
}
