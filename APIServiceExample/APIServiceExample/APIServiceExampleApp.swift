//
//  APIServiceExampleApp.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 11/05/2023.
//

import SwiftUI

@main
struct APIServiceExampleApp: App {
    @UIApplicationDelegateAdaptor var delegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
