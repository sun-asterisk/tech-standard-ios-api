//
//  APIServiceExampleApp.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 11/05/2023.
//

import SwiftUI

@main
struct APIServiceExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainView()
                    .navigationTitle("Repo List")
            }
        }
    }
}
