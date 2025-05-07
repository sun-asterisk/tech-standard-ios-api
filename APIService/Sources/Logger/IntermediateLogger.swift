import Foundation
import os.log

/// A logger implementation that logs intermediate level details about API requests and responses.
open class IntermediateLogger: BaseLogger {
    /// The shared singleton instance of IntermediateLogger.
    public static let shared = IntermediateLogger()
    
    public override init() {
        super.init()
    }
    
    open override func logRequest(_ request: URLRequest) {
        let method = request.httpMethod ?? "UNKNOWN"
        let urlString = request.url?.absoluteString ?? ""
        var logString = method + " " + urlString + "\n"
        
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                logString += "\(key): \(value)\n"
            }
        }
        
        if let bodyData = request.httpBody, let bodyString = bodyData.toJSONString(prettyPrinted: prettyPrinted) {
            logString += bodyString
        }
        
        if let prefix {
            logString = prefix + " " + logString
        }
        
        log.log(logString)
    }
    
    open override func logResponse(forRequest request: URLRequest?, response: URLResponse?, data: Data?) {
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
