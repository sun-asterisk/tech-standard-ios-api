import Foundation

/// A compact logger implementation that logs minimal information about API requests and responses.
open class CompactLogger: BaseLogger {
    public static let shared = CompactLogger()
    
    public override init() {
        super.init()
    }
    
    /// Logs minimal information about a URLRequest.
    ///
    /// - Parameter urlRequest: The URLRequest to log.
    open override func logRequest(_ urlRequest: URLRequest) {
        let method = urlRequest.httpMethod ?? "UNKNOWN"
        let urlString = urlRequest.url?.absoluteString ?? ""
        var logString = method + " " + urlString
        
        if let prefix {
            logString = prefix + " " + logString
        }
        
        log.log(logString)
    }
    
    /// Logs minimal information about a URLResponse, including status code and URL.
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
        
        if let prefix {
            logString = prefix + " " + logString
        }
        
        log.log(logString)
    }
}
