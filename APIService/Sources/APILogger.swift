import Foundation
import os.log

/// Protocol for logging API requests and responses.
public protocol APILogger: AnyObject {
    /// Logs the details of a URLRequest.
    ///
    /// - Parameter urlRequest: The URLRequest to log.
    func logRequest(_ urlRequest: URLRequest)
    
    /// Logs the details of a URLResponse along with any associated data.
    ///
    /// - Parameters:
    ///   - response: The URLResponse to log.
    ///   - data: The data associated with the response, if any.
    func logResponse(_ response: URLResponse?, data: Data?)
}

/// A verbose logger implementation that logs detailed information about API requests and responses.
public class VerboseLogger: APILogger {
    public static let shared = VerboseLogger()
    
    /// Optional prefix to add to log messages.
    public var prefix: String? = "[API]"
    
    /// Logs detailed information about a URLRequest, including headers and body.
    ///
    /// - Parameter urlRequest: The URLRequest to log.
    public func logRequest(_ urlRequest: URLRequest) {
        var logString = "\(urlRequest.httpMethod ?? "UNKNOWN") \(urlRequest.url?.path ?? "UNKNOWN")\n"
        
        if let host = urlRequest.url?.host {
            logString += "Host: \(host)\n"
        }
        
        if let headers = urlRequest.allHTTPHeaderFields {
            for (key, value) in headers {
                logString += "\(key): \(value)\n"
            }
        }
        
        if let bodyData = urlRequest.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            logString += "\n\(bodyString)"
        }
        
        if let prefix {
            logString = prefix + " " + logString
        }
        
        os_log("%{PUBLIC}@", log: .default, type: .info, logString)
    }
    
    /// Logs detailed information about a URLResponse, including status code, headers, and body.
    ///
    /// - Parameters:
    ///   - response: The URLResponse to log.
    ///   - data: The data associated with the response, if any.
    public func logResponse(_ response: URLResponse?, data: Data?) {
        var logString = ""
        
        if let httpResponse = response as? HTTPURLResponse {
            logString += "\(httpResponse.statusCode) (\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))) \(httpResponse.url?.path ?? "")\n"
            
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
            logString += "\n\(String(data: data, encoding: .utf8) ?? "Bad Data")"
        }
        
        if let prefix {
            logString = prefix + " " + logString
        }
        
        os_log("%{PUBLIC}@", log: .default, type: .info, logString)
    }
}

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
