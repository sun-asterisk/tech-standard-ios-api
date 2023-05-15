//
//  RepoDetailView.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 15/05/2023.
//

import SwiftUI
import Combine
import Factory

struct RepoDetailView: View, GetEvents {
    private enum ViewState {
        case isLoading, loaded, loadingMore, reloading
    }
    
    // Dependencies
    @Injected(\.repoGateway) var repoGateway: RepoGatewayProtocol
    
    // Init
    let repo: Repo
    
    // State
    @State private var cancelBag = CancelBag()
    @State private var events = [Event]()
    @State private var error: IDError?
    @State private var state = ViewState.isLoading
    @State private var page = 1
    
    // Properties
    private let perPage = 20
    
    var body: some View {
        List {
            Section {
                VStack {
                    AsyncImage(url: URL(string: repo.owner?.avatarUrl ?? ""), scale: 2) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.5)
                    }
                    .frame(width: 120, height: 120)
                    .cornerRadius(10)
                    
                    Text(repo.fullName)
                        .font(.title)
                }
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
                
                Text("Star")
                    .badge(repo.stars)
                
                Text("Fork")
                    .badge(repo.forks)
            }
            
            Section("Events") {
                if state == .isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(events) { event in
                        EventView(event: event)
                    }
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
                        loadMoreEvents()
                    }
            }
            
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .alert(error: $error)
        .refreshable {
            reloadEvents()
        }
        .onAppear {
            loadEvents()
        }
    }
}

// MARK: - Methods
private extension RepoDetailView {
    func loadEvents() {
        getEvents(url: repo.eventUrl, page: 1, perPage: perPage)
            .handleFailure(error: $error)
            .sink { events in
                self.state = .loaded
                self.events = events
            }
            .store(in: cancelBag)
    }
    
    func reloadEvents() {
        guard state == .loaded else { return }
        state = .reloading
        loadEvents()
    }
    
    func loadMoreEvents() {
        guard state == .loaded else { return }
        state = .loadingMore

        getEvents(url: repo.eventUrl, page: page + 1, perPage: perPage)
            .handleFailure(error: $error)
            .sink { events in
                self.page += 1
                self.events += events
                state = .loaded
            }
            .store(in: cancelBag)
    }
}
