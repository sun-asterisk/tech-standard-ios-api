import Foundation
import Combine
import UIKit

/// A protocol that defines the requirements for an API service.
public protocol APIService {
    /// The URLSession instance used to perform network requests.
    var session: URLSession { get }
}

/// An enumeration representing possible errors that can occur during API requests.
public enum APIError: Error {
    /// Represents an error when the HTTP response status code is not in the range 200-299.
    case httpResponse(response: HTTPURLResponse)
}

public extension APIService {
    /// Performs a network request and decodes the response data into a specified type.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to request.
    ///   - decodingType: The type to decode the response data into.
    ///   - decoder: The decoder to use for decoding the response data. Default is `JSONDecoder()`.
    ///   - queue: The dispatch queue to receive the response on. Default is `.main`.
    ///   - retries: The number of times to retry the request in case of failure. Default is 0.
    /// - Returns: A publisher that emits the decoded response data or an error.
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
    
    /// Performs a network request and returns the response data.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to request.
    ///   - queue: The dispatch queue to receive the response on. Default is `.main`.
    /// - Returns: A publisher that emits the response data or a URL error.
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
    
    /// Performs a network request to download a file and returns the file URL.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to request.
    ///   - queue: The dispatch queue to receive the response on. Default is `.main`.
    /// - Returns: A publisher that emits the file URL or a URL error.
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
