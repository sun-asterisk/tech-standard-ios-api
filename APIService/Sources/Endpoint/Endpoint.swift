import Foundation
import MobileCoreServices

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
    /// The base URL for the endpoint.
    var base: String? { get }
    
    /// The path component for the endpoint.
    var path: String? { get }
    
    /// A complete URL string for the endpoint. If provided, it takes precedence over `base` and `path`.
    var urlString: String? { get }
    
    /// The HTTP method for the endpoint.
    var httpMethod: HttpMethod { get }
    
    /// The headers for the endpoint.
    var headers: [String: Any]? { get }
    
    /// The query items for the endpoint.
    var queryItems: [(String, Any)]? { get }
    
    /// The body parameters for the endpoint.
    var body: [String: Any]? { get }
    
    /// The raw body data for the endpoint.
    var bodyData: Data? { get }
    
    /// The multipart form data for the endpoint.
    var parts: [MultipartFormData] { get }
}

/// Default implementations for the Endpoint protocol.
public extension Endpoint {
    var base: String? { nil }
    var path: String? { nil }
    var urlString: String? { nil }
    var httpMethod: HttpMethod { .get }
    var headers: [String: Any]? { nil }
    var queryItems: [(String, Any)]? { nil }
    var body: [String: Any]? { nil }
    var bodyData: Data? { nil }
    var parts: [MultipartFormData] { [] }
}

private extension String {
    /// Safely converts a string to UTF-8 encoded data.
    var utf8Data: Data {
        data(using: .utf8) ?? Data()
    }
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
                + queryItems.map { (name, value) in
                    return URLQueryItem(name: name, value: "\(value)")
                }
        }
        
        return components
    }
    
    /// Constructs a URLRequest from the endpoint's properties.
    var urlRequest: URLRequest? {
        guard let url = urlComponents?.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        
        // Set headers first to allow them to be overridden by body-specific headers
        headers?
            .compactMapValues { $0 as? String }
            .forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Handle body with priority: parts > bodyData > body
        if !parts.isEmpty {
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = createMultipartBody(parts: parts, boundary: boundary)
        } else if let bodyData {
            // Use bodyData as-is if provided
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            }
            request.httpBody = bodyData
        } else if let body {
            // Serialize body to JSON
            if let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) {
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
                request.httpBody = jsonData
            }
        }
        
        return request
    }
    
    /// Creates multipart form data body.
    ///
    /// - Parameters:
    ///   - parts: The multipart form data parts.
    ///   - boundary: The boundary string for separating parts.
    /// - Returns: The multipart form data as `Data`.
    private func createMultipartBody(parts: [MultipartFormData], boundary: String) -> Data {
        var bodyData = Data()
        let lineBreak = "\r\n"
        
        // Add body parameters as form fields if present
        if let parameters = body {
            for (key, value) in parameters {
                bodyData.append("--\(boundary)\(lineBreak)".utf8Data)
                bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)".utf8Data)
                bodyData.append("\(value)\(lineBreak)".utf8Data)
            }
        }
        
        // Add multipart form data parts
        for part in parts {
            bodyData.append("--\(boundary)\(lineBreak)".utf8Data)
            
            switch part.provider {
            case .data(let data):
                if let fileName = part.fileName {
                    bodyData.append("Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(fileName)\"\(lineBreak)".utf8Data)
                } else {
                    bodyData.append("Content-Disposition: form-data; name=\"\(part.name)\"\(lineBreak)\(lineBreak)".utf8Data)
                }
                
                if let mimeType = part.mimeType {
                    bodyData.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)".utf8Data)
                }
                
                bodyData.append(data)
                
            case .file(let url):
                if let fileData = try? Data(contentsOf: url) {
                    if let fileName = part.fileName {
                        bodyData.append("Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(fileName)\"\(lineBreak)".utf8Data)
                    } else {
                        bodyData.append("Content-Disposition: form-data; name=\"\(part.name)\"\(lineBreak)\(lineBreak)".utf8Data)
                    }
                    
                    let mimeType = part.mimeType ?? mimeType(for: url)
                    bodyData.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)".utf8Data)
                    
                    bodyData.append(fileData)
                }
            }
            
            bodyData.append(lineBreak.utf8Data)
        }
        
        bodyData.append("--\(boundary)--\(lineBreak)".utf8Data)
        return bodyData
    }
    
    /// Determines the MIME type for a given file URL.
    ///
    /// - Parameter url: The file URL to determine the MIME type for.
    /// - Returns: The MIME type string, or "application/octet-stream" as a default.
    private func mimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension as NSString
        
        // Try using system UTI first (iOS 14+)
        if #available(iOS 14.0, *) {
            guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)?.takeRetainedValue(),
                  let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() else {
                return "application/octet-stream" // default MIME type
            }
            return mimeType as String
        }
        
        // Fallback to manual mapping
        let mimeTypes: [String: String] = [
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "png": "image/png",
            "gif": "image/gif",
            "pdf": "application/pdf",
            "txt": "text/plain",
            "json": "application/json",
            "xml": "application/xml",
            "zip": "application/zip",
            "mp4": "video/mp4",
            "mp3": "audio/mpeg",
            "wav": "audio/wav",
            "doc": "application/msword",
            "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "xls": "application/vnd.ms-excel",
            "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "ppt": "application/vnd.ms-powerpoint",
            "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        ]
        
        return mimeTypes[pathExtension.lowercased] ?? "application/octet-stream"
    }
}
