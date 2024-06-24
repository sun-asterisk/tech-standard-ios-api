import Combine
import Foundation
import APIService

class TokenManager {
    static let shared = TokenManager()
    weak var delegate: TokenManagerDelegate?
    
    private let tokenSubject = CurrentValueSubject<String?, Never>(nil)
    private let semaphore = DispatchSemaphore(value: 1)
    
    private init() {}
    
    func setToken(_ token: String) {
        tokenSubject.send(token)
    }

    func validToken() -> AnyPublisher<String, Error> {
        return tokenSubject
            .flatMap { token -> AnyPublisher<String, Error> in
                guard let token = token else {
                    return self.refreshToken()
                }
                
                return Just(token).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func refreshToken() -> AnyPublisher<String, Error> {
        return Future { [weak self] promise in
            self?.semaphore.wait()
            
            if let token = self?.tokenSubject.value {
                self?.semaphore.signal()
                promise(.success(token))
            } else if let delegate = self?.delegate  {
                delegate.refreshToken(token: "token") { result in
                    switch result {
                    case .success(let newToken):
                        self?.tokenSubject.send(newToken)
                        self?.semaphore.signal()
                        promise(.success(newToken))
                    case .failure(let error):
                        self?.semaphore.signal()
                        promise(.failure(error))
                    }
                }
            } else {
                fatalError("No delegate assigned")
            }
        }
        .eraseToAnyPublisher()
    }
}

protocol TokenManagerDelegate: AnyObject {
    func refreshToken(token: String, completion: (Result<String, Error>) -> Void)
}

extension AnyPublisher where Output == Endpoint {
    func addToken(manager: TokenManager) -> AnyPublisher<Endpoint, Error> {
        return self.map { endpoint in
            return manager.validToken()
                .map { token in
                    endpoint.add(headersToMerge: ["access_token": token])
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
                    self.request(ep, decodingType: decodingType, decoder: decoder, queue: queue)
                }
                .switchToLatest()
                .eraseToAnyPublisher()
        }

        return createPublisher()
            .retry(retries)
            .eraseToAnyPublisher()
    }
}
