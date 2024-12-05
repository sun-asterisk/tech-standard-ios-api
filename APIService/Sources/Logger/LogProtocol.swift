//
//  LogProtocol.swift
//  APIService
//
//  Created by truong.anh.tuan on 5/12/24.
//

import os.log

/// Protocol for logging messages.
public protocol LogProtocol {
    func log(_ message: String)
}

/// A logger that logs messages to the OS log.
open class OSLog: LogProtocol {
    public static let shared = OSLog()
    
    public init() { }
    
    public func log(_ message: String) {
        os_log("%{PUBLIC}@", log: .default, type: .info, message)
    }
}

/// A logger that logs messages to the console.
open class ConsoleLog: LogProtocol {
    public static let shared = ConsoleLog()
    
    public init() { }
    
    public func log(_ message: String) {
        print(message)
    }
}

public enum Logs {
    public static let os = OSLog.shared
    public static let console = ConsoleLog.shared
}
