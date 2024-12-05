//
//  File.swift
//  APIService
//
//  Created by truong.anh.tuan on 5/12/24.
//

import Foundation

/// Base class for logging API requests and responses.
open class BaseLogger: APILogger {
    /// Optional prefix to add to log messages.
    open var prefix: String? = "[API]"
    
    /// Determines if the logged JSON should be pretty printed.
    open var prettyPrinted = false
    
    /// The maximum length of the logged data.
    open var maxLength = 500
    
    /// The log to use for logging.
    open var log: LogProtocol = OSLog()
    
    public func logRequest(_ urlRequest: URLRequest) {
        fatalError("Subclasses must implement this method")
    }

    public func logResponse(_ response: URLResponse?, data: Data?) {
        fatalError("Subclasses must implement this method")
    }
}
