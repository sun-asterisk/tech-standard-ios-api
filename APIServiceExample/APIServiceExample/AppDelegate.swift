//
//  AppDelegate.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 5/6/24.
//

import Foundation
import UIKit
import APIService

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        TokenManager.shared.token = Token(accessToken: "a token", refreshToken: "a refresh token", isExpired: true)
        DefaultAPIService.shared.logger = APILoggers.verbose
        APILoggers.verbose.log = Logs.console
        APILoggers.verbose.prettyPrinted = true
        APILoggers.verbose.maxLength = 2000
//        APILoggers.intermediate.prettyPrinted = true
//        APILoggers.intermediate.maxLength = 1000
//        CompactLogger.shared.prefix = nil
        
        return true
    }
}
