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
