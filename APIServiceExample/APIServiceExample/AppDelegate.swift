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
        TokenManager.shared.setToken("test token")
//        DefaultAPIService.shared.logger = VerboseLogger.shared
        CompactLogger.shared.prefix = nil
        
        return true
    }
}
