import Foundation
import Combine
import UIKit

public protocol APIService {
    var session: URLSession { get }
}

public enum APIError: Error {
    case httpResponse(response: HTTPURLResponse)
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
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                guard 200..<300 ~= httpResponse.statusCode else {
                    throw APIError.httpResponse(response: httpResponse)
                }
                
                return output.data
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
    
    func download(
        _ endpoint: Endpoint,
        queue: DispatchQueue = .main
    ) -> AnyPublisher<URL, URLError> {
        guard let urlRequest = endpoint.urlRequest else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return session.downloadTaskPublisher(for: urlRequest)
            .map { $0.url }
            .mapError { $0 as URLError }
            .receive(on: queue)
            .eraseToAnyPublisher()
    }
}
