import Foundation
import os.log

/// A compact logger implementation that logs minimal information about API requests and responses.
public class CompactLogger: APILogger {
    public static let shared = CompactLogger()
    
    /// Optional prefix to add to log messages.
    public var prefix: String? = "[API]"
    
    /// Logs minimal information about a URLRequest.
    ///
    /// - Parameter urlRequest: The URLRequest to log.
    public func logRequest(_ urlRequest: URLRequest) {
        let method = urlRequest.httpMethod ?? "UNKNOWN"
        let urlString = urlRequest.url?.absoluteString ?? ""
        var logString = method + " " + urlString
        
        if let prefix {
            logString = prefix + " " + logString
        }
        
        os_log("%{PUBLIC}@", log: .default, type: .info, logString)
    }
    
    /// Logs minimal information about a URLResponse, including status code and URL.
    ///
    /// - Parameters:
    ///   - response: The URLResponse to log.
    ///   - data: The data associated with the response, if any.
    public func logResponse(_ response: URLResponse?, data: Data?) {
        var logString = ""
        
        if let httpResponse = response as? HTTPURLResponse {
            logString += "\(httpResponse.statusCode) " + (httpResponse.url?.absoluteString ?? "")
        } else {
            logString += "Bad Response"
        }
        
        if let prefix {
            logString = prefix + " " + logString
        }
        
        os_log("%{PUBLIC}@", log: .default, type: .info, logString)
    }
}
