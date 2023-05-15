//
//  RepoUseCases.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 15/05/2023.
//

import Combine

// MARK: - Get repos
protocol GetRepos {
    var repoGateway: RepoGatewayProtocol { get }
}

extension GetRepos {
    func getRepos(page: Int, perPage: Int) -> AnyPublisher<[Repo], Error> {
        repoGateway.getRepos(page: page, perPage: perPage)
    }
}

// MARK: - Get events
protocol GetEvents {
    var repoGateway: RepoGatewayProtocol { get }
}

extension GetEvents {
    func getEvents(url: String, page: Int, perPage: Int) -> AnyPublisher<[Event], Error> {
        repoGateway.getEvents(url: url, page: page, perPage: perPage)
    }
}
