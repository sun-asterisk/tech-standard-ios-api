import Foundation
import os.log

/// A verbose logger implementation that logs detailed information about API requests and responses.
open class VerboseLogger: BaseLogger {
    /// The shared singleton instance of VerboseLogger.
    public static let shared = VerboseLogger()
    
    public override init() {
        super.init()
    }
    
    open override func logRequest(_ request: URLRequest) {
        let httpMethod = request.httpMethod ?? "UNKNOWN"
        let path = request.url?.path ?? "UNKNOWN"
        var logString = "\(httpMethod) \(path)\n"
        
        if let queryItems = request.url?.query {
            logString += "Query: \(queryItems)\n"
        }
        
        if let host = request.url?.host {
            logString += "Host: \(host)\n"
        }
        
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                logString += "\(key): \(value)\n"
            }
        }
        
        if let bodyData = request.httpBody, let bodyString = bodyData.toJSONString(prettyPrinted: prettyPrinted) {
            logString += "\n\(bodyString)"
        }
        
        if let prefix {
            logString = prefix + " " + logString
        }
        
        log.log(logString)
    }
    
    open override func logResponse(forRequest request: URLRequest?, response: URLResponse?, data: Data?) {
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
