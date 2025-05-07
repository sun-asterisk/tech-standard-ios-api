import Foundation
import os.log

/// Protocol for logging API requests and responses.
public protocol APILogger: AnyObject {
    /// Logs the details of a URLRequest.
    ///
    /// - Parameter request: The URLRequest to log.
    func logRequest(_ request: URLRequest)
    
    /// Logs the details of a URLResponse along with any associated data.
    ///
    /// - Parameters:
    ///   - request: The URLRequest associated with the response.
    ///   - response: The URLResponse to log.
    ///   - data: The data associated with the response, if any.
    func logResponse(forRequest request: URLRequest?, response: URLResponse?, data: Data?)
}
