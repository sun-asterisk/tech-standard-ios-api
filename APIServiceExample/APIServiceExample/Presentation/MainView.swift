//
//  MainView.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 15/05/2023.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            RepoListView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
