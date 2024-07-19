import Foundation
import os.log

public protocol APILogger: AnyObject {
    func logRequest(_ urlRequest: URLRequest)
    func logResponse(_ response: URLResponse?, data: Data?)
}

public class VerboseLogger: APILogger {
    public static let shared = VerboseLogger()
    
    public var prefix: String? = "[API]"
    
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

public class CompactLogger: APILogger {
    public static let shared = CompactLogger()
    
    public var prefix: String? = "[API]"
    
    public func logRequest(_ urlRequest: URLRequest) {
        let method = urlRequest.httpMethod ?? "UNKNOWN"
        let urlString = urlRequest.url?.absoluteString ?? ""
        var logString = method + " " + urlString
        
        if let prefix {
            logString = prefix + " " + logString
        }
        
        os_log("%{PUBLIC}@", log: .default, type: .info, logString)
    }
    
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
