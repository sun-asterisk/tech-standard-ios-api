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
        BaseEndpoint.gitRepos
            .add(headers: { ep in
                let device = "iOS"
                
                if var currentHeaders = ep.headers {
                    currentHeaders["Device"] = device
                    return currentHeaders
                }
                
                return ["Device": device]
            })
            .add(additionalHeaders: ["version": 1.5])
            .publisher
            .addToken(manager: TokenManager.shared)
            .map { $0.add(httpMethod: .get) }
            .flatMap { ep in
                APIServices.default
                    .request(ep)
                    .data(type: GetReposResult.self)
            }
            .map(\.items)
            .eraseToAnyPublisher()
    }
    
    func getEvents(url: String, page: Int, perPage: Int) -> AnyPublisher<[Event], Error> {
        APIServices.default
            .request(GitEndpoint.events(url: url, page: page, perPage: perPage))
//            .request(url.toEndpoint().add(queryItems: [
//                "per_page": perPage,
//                "page": page
//            ]))
//            .request(url)
            .data(type: [Event].self)
            .eraseToAnyPublisher()
    }
}

extension Container {
    var repoGateway: Factory<RepoGatewayProtocol> {
        Factory(self) { RepoGateway() }
    }
}

// Example
class MyAPIService: APIService {
    var session: URLSession = URLSession.shared
    
    func requestData(
        _ endpoint: Endpoint,
        queue: DispatchQueue = .main
    ) -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error> {
        self.request(endpoint, queue: queue)
            // .handleError()
            .eraseToAnyPublisher()
    }
    
    func requestDataWithToken(
        _ endpoint: Endpoint,
        queue: DispatchQueue = .main
    ) -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error> {
        GitEndpoint.repos(page: 1, perPage: 10)
            .publisher
            .addToken(manager: TokenManager.shared)
            .flatMap { [unowned self] ep in
                self.request(endpoint, queue: queue)
            }
            // .handleError()
            .eraseToAnyPublisher()
    }
    
    func requestPlain(_ endpoint: Endpoint) -> AnyPublisher<Void, Error> {
        requestData(endpoint)
            .plain()
    }
    
    func getEvents(_ endpoint: Endpoint) -> AnyPublisher<[Event], Error> {
        requestData(endpoint)
            .data(type: [Event].self)
            .eraseToAnyPublisher()
    }
}
