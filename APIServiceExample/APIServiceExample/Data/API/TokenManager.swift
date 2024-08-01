import Combine
import Foundation
import APIService

struct Token: Equatable {
    var accessToken = ""
    var refreshToken = ""
    var isExpired = false
}

enum AppSettings {
    static var token: Token?
}

class TokenManager {
    static let shared = TokenManager()
    private let semaphore = DispatchSemaphore(value: 1)
    
    private init() {}
    private var _token: Token?
    
    var token: Token? {
        get {
            return _token ?? AppSettings.token
        }
        set {
            guard let token = newValue, token != _token else { return }
            _token = token
            AppSettings.token = token
        }
    }
    
    func refreshToken() -> AnyPublisher<Token, Error> {
        Just(Token(accessToken: "a new token", refreshToken: "a new refresh token", isExpired: false))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func validToken() -> AnyPublisher<Token, Error> {
        Just(token)
            .setFailureType(to: Error.self)
            .flatMap { [unowned self] token in
                semaphore.wait()
                
                if let token, !token.isExpired {
                    return Just(token).setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } else {
                    return refreshToken()
                        .eraseToAnyPublisher()
                }
            }
            .handleEvents(receiveOutput: { [unowned self] token in
                self.token = token
            }, receiveCompletion: { [unowned self] _ in
                semaphore.signal()
            }, receiveCancel: { [unowned self] in
                semaphore.signal()
            })
            .eraseToAnyPublisher()
    }
}

extension AnyPublisher where Output == Endpoint {
    func addToken(manager: TokenManager) -> AnyPublisher<Endpoint, Error> {
        return self.map { endpoint in
            return manager.validToken()
                .map { token in
                    endpoint.append(headers: ["access_token": token])
                }
        }
        .mapError { $0 as Error }
        .switchToLatest()
        .eraseToAnyPublisher()
    }
}

extension APIService {
    func requestWithToken<T, Decoder>(
        _ endpoint: Endpoint,
        decodingType: T.Type,
        decoder: Decoder = JSONDecoder(),
        queue: DispatchQueue = .main,
        retries: Int = 0
    )  -> AnyPublisher<T, Error> where T: Decodable, Decoder: TopLevelDecoder, Decoder.Input == Data {
        func createPublisher() -> AnyPublisher<T, Error> {
            endpoint.publisher
                .addToken(manager: TokenManager.shared)
                .map { ep in
                    self.request(ep, queue: queue)
                        .data(type: decodingType, decoder: decoder)
                }
                .switchToLatest()
                .eraseToAnyPublisher()
        }

        return createPublisher()
            .retry(retries)
            .eraseToAnyPublisher()
    }
}
