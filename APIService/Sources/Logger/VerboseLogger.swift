import Foundation
import os.log

/// A verbose logger implementation that logs detailed information about API requests and responses.
open class VerboseLogger: BaseLogger {
    /// The shared singleton instance of VerboseLogger.
    public static let shared = VerboseLogger()
    
    public override init() {
        super.init()
    }
    
    /// Logs detailed information about a URLRequest, including headers and body.
    ///
    /// - Parameter urlRequest: The URLRequest to log.
    open override func logRequest(_ urlRequest: URLRequest) {
        let httpMethod = urlRequest.httpMethod ?? "UNKNOWN"
        let path = urlRequest.url?.path ?? "UNKNOWN"
        var logString = "\(httpMethod) \(path)\n"
        
        if let queryItems = urlRequest.url?.query {
            logString += "Query: \(queryItems)\n"
        }
        
        if let host = urlRequest.url?.host {
            logString += "Host: \(host)\n"
        }
        
        if let headers = urlRequest.allHTTPHeaderFields {
            for (key, value) in headers {
                logString += "\(key): \(value)\n"
            }
        }
        
        if let bodyData = urlRequest.httpBody, let bodyString = bodyData.toJSONString(prettyPrinted: prettyPrinted) {
            logString += "\n\(bodyString)"
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
            logString += "\(httpResponse.statusCode) (\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))) \(httpResponse.url?.path ?? "")\n"
            
            if let queryItems = httpResponse.url?.query {
                logString += "Query: \(queryItems)\n"
            }
            
            if let host = httpResponse.url?.host {
                logString += "Host: \(host)\n"
            }
            
            for (key, value) in httpResponse.allHeaderFields {
                logString += "\(key): \(value)\n"
            }
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
