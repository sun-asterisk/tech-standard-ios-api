//
//  RepoGateway.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 15/05/2023.
//

import Foundation
import Factory
import Combine
import APIService

protocol RepoGatewayProtocol {
    func getRepos(page: Int, perPage: Int) -> AnyPublisher<[Repo], Error>
    func getEvents(url: String, page: Int, perPage: Int) -> AnyPublisher<[Event], Error>
}

final class RepoGateway: RepoGatewayProtocol {
    private struct GetReposResult: Decodable {
        var items = [Repo]()
    }
    
    func getRepos(page: Int, perPage: Int) -> AnyPublisher<[Repo], Error> {
        DefaultAPIService.shared
            .request(GitEndpoint.repos(page: page, perPage: perPage), decodingType: GetReposResult.self)
            .map(\.items)
            .eraseToAnyPublisher()
    }
    
    func getEvents(url: String, page: Int, perPage: Int) -> AnyPublisher<[Event], Error> {
        DefaultAPIService.shared
            .request(GitEndpoint.events(url: url, page: page, perPage: perPage), decodingType: [Event].self)
            .eraseToAnyPublisher()
    }
}

extension Container {
    var repoGateway: Factory<RepoGatewayProtocol> {
        Factory(self) { RepoGateway() }
    }
}

