import Foundation
import os.log

/// A logger implementation that logs intermediate level details about API requests and responses.
open class IntermediateLogger: BaseLogger {
    /// The shared singleton instance of IntermediateLogger.
    public static let shared = IntermediateLogger()
    
    public override init() {
        super.init()
    }
    
    /// Logs detailed information about a URLRequest, including headers and body.
    ///
    /// - Parameter urlRequest: The URLRequest to log.
    open override func logRequest(_ urlRequest: URLRequest) {
        let method = urlRequest.httpMethod ?? "UNKNOWN"
        let urlString = urlRequest.url?.absoluteString ?? ""
        var logString = method + " " + urlString + "\n"
        
        if let headers = urlRequest.allHTTPHeaderFields {
            for (key, value) in headers {
                logString += "\(key): \(value)\n"
            }
        }
        
        if let bodyData = urlRequest.httpBody, let bodyString = bodyData.toJSONString(prettyPrinted: prettyPrinted) {
            logString += bodyString
        }
        
        if let prefix {
            logString = prefix + " " + logString
        }
        
        log.log(logString)
    }
    
    /// Logs detailed information about a URLResponse, including status code, headers, and body.
    ///
    /// - Parameters:
    ///   - response: The URLResponse to log.
    ///   - data: The data associated with the response, if any.
    open override func logResponse(_ response: URLResponse?, data: Data?) {
        var logString = ""
        
        if let httpResponse = response as? HTTPURLResponse {
            logString += "\(httpResponse.statusCode) " + (httpResponse.url?.absoluteString ?? "")
        } else {
            logString += "Bad Response"
        }
        
        if let data {
            logString += "\n\(data.toJSONString(prettyPrinted: prettyPrinted, maxLength: maxLength) ?? "Bad Response Data")"
        }
        
        if let prefix {
            logString = prefix + " " + logString
        }
        
        log.log(logString)
    }
}
