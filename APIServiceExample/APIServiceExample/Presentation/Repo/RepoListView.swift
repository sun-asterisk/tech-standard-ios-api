//
//  RepoListView.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 15/05/2023.
//

import SwiftUI
import Factory
import Combine

struct RepoListView: View, GetRepos {
    private enum ViewState {
        case isLoading, loaded, loadingMore, reloading
    }
    
    // Dependencies
    @Injected(\.repoGateway) var repoGateway: RepoGatewayProtocol
    
    // State
    @State private var cancelBag = CancelBag()
    @State private var repos = [Repo]()
    @State private var error: IDError?
    @State private var state = ViewState.isLoading
    @State private var page = 1
    
    private let perPage = 20
    
    var body: some View {
        content
            .navigationTitle("Repo List")
    }
}

// MARK: - Views
private extension RepoListView {
    @ViewBuilder
    var content: some View {
        switch state {
        case .isLoading:
            loadingView()
        case .loaded, .loadingMore, .reloading:
            listView()
        }
    }
    
    @ViewBuilder
    func loadingView() -> some View {
        ProgressView()
            .progressViewStyle(.circular)
            .onAppear {
                loadRepos()
            }
    }
    
    @ViewBuilder
    func listView() -> some View {
        List {
            ForEach(repos) { repo in
                NavigationLink {
                    RepoDetailView(repo: repo)
                } label: {
                    RepoView(repo: repo)
                }
            }
            
            if state == .loadingMore {
                ProgressView()
                    .progressViewStyle(.circular)
                    .listRowSeparator(.hidden)
                    .frame(maxWidth: .infinity, alignment: .center)
                    
            } else {
                Color.clear
                    .listRowSeparator(.hidden)
                    .padding()
                    .onAppear {
                        loadMoreRepos()
                    }
            }
        }
        .refreshable {
            loadRepos()
        }
        .listStyle(.plain)
        .alert(error: $error)
    }
}

// MARK: - Methods
private extension RepoListView {
    func loadRepos() {
        getRepos(page: 1, perPage: perPage)
            .handleFailure(error: $error)
            .sink { repos in
                self.page = 1
                self.repos = repos
                state = .loaded
            }
            .store(in: cancelBag)
    }
    
    func reloadRepos() {
        guard state == .loaded else { return }
        state = .reloading
        loadRepos()
    }
    
    func loadMoreRepos() {
        guard state == .loaded else { return }
        state = .loadingMore

        getRepos(page: page + 1, perPage: perPage)
            .handleFailure(error: $error)
            .sink { repos in
                self.page += 1
                self.repos += repos
                state = .loaded
            }
            .store(in: cancelBag)
    }
}
