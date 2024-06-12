import Foundation
import Combine
import UIKit

public protocol APIService {
    var session: URLSession { get }
}

public extension APIService {
    func request<T, Decoder>(
        _ endpoint: Endpoint,
        decodingType: T.Type,
        decoder: Decoder = JSONDecoder(),
        queue: DispatchQueue = .main,
        retries: Int = 0
    ) -> AnyPublisher<T, Error> where T: Decodable, Decoder: TopLevelDecoder, Decoder.Input == Data {
        guard let urlRequest = endpoint.urlRequest else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
    
        return session.dataTaskPublisher(for: urlRequest)
            .tryMap {
                guard let response = $0.response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return $0.data
            }
            .decode(type: T.self, decoder: decoder)
            .receive(on: queue)
            .retry(retries)
            .eraseToAnyPublisher()
    }
    
    func requestData(
        _ endpoint: Endpoint,
        queue: DispatchQueue = .main
    ) -> AnyPublisher<Data, URLError> {
        guard let urlRequest = endpoint.urlRequest else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: urlRequest)
            .map { $0.data }
            .mapError { $0 as URLError }
            .receive(on: queue)
            .eraseToAnyPublisher()
    }
}
