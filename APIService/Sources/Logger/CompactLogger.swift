import Foundation

/// A compact logger implementation that logs minimal information about API requests and responses.
open class CompactLogger: BaseLogger {
    public static let shared = CompactLogger()
    
    public override init() {
        super.init()
    }
    
    open override func logRequest(_ request: URLRequest) {
        let method = request.httpMethod ?? "UNKNOWN"
        let urlString = request.url?.absoluteString ?? ""
        var logString = method + " " + urlString
        
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
        
        if let prefix {
            logString = prefix + " " + logString
        }
        
        log.log(logString)
    }
}
