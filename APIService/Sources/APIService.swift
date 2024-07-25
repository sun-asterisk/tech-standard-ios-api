import Foundation
import Combine
import UIKit
import os.log

/// A protocol that defines the requirements for an API service.
public protocol APIService: AnyObject {
    /// The URLSession instance used to perform network requests.
    var session: URLSession { get }
    var logger: APILogger? { get }
}

public extension APIService {
    var logger: APILogger? { APILoggers.compact }
}

/// An enumeration representing possible errors that can occur during API requests.
public enum APIError: Error {
    /// Represents an error when the HTTP response status code is not in the range 200-299.
    case badRequest(response: HTTPURLResponse, data: Data)
}

public extension APIService {
    /// Performs a network request and returns the raw response and data.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to request.
    ///   - queue: The dispatch queue to receive the response on. Default is `.main`.
    /// - Returns: A publisher that emits a tuple containing the URLResponse and the response Data, or an error.
    func request(
        _ endpoint: Endpoint,
        queue: DispatchQueue = .main
    ) -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error>  {
        guard let urlRequest = endpoint.urlRequest else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        logger?.logRequest(urlRequest)
        
        return session.dataTaskPublisher(for: urlRequest)
            .tryMap { [weak self] output in
                self?.logger?.logResponse(output.response, data: output.data)
                
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                guard 200..<300 ~= httpResponse.statusCode else {
                    throw APIError.badRequest(response: httpResponse, data: output.data)
                }
                
                return output
            }
            .receive(on: queue)
            .eraseToAnyPublisher()
    }
}

public extension AnyPublisher where Output == URLSession.DataTaskPublisher.Output, Failure == Error {
    /// Transforms the publisher to decode the data into a specified type.
    ///
    /// - Parameters:
    ///   - type: The type to decode the data into.
    ///   - decoder: The decoder to use for decoding the data. Defaults to `JSONDecoder`.
    /// - Returns: A publisher that emits the decoded type or an error.
    func data<T, Decoder>(
        type: T.Type,
        decoder: Decoder = JSONDecoder()
    ) -> AnyPublisher<T, Error> where T: Decodable, Decoder: TopLevelDecoder, Decoder.Input == Data {
        map { $0.data }
            .decode(type: T.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    /// Transforms the publisher to emit only the raw data.
    ///
    /// - Returns: A publisher that emits the data or an error.
    func data() -> AnyPublisher<Data, Error> {
        map { $0.data }
            .eraseToAnyPublisher()
    }
    
    /// Transforms the publisher to emit a `Void` value, effectively ignoring the data.
    ///
    /// - Returns: A publisher that emits `Void` or an error.
    func plain() -> AnyPublisher<Void, Error> {
        map { _ in () }
            .eraseToAnyPublisher()
    }
    
    func json() -> AnyPublisher<[String: Any], Error> {
        tryMap {
            try JSONSerialization.jsonObject(with: $0.data, options: []) as! [String: Any]
        }
        .eraseToAnyPublisher()
    }
}

public extension APIService {
    
    /// Performs a network request and decodes the response data into a specified type.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to request.
    ///   - decodingType: The type to decode the response data into.
    ///   - decoder: The decoder to use for decoding the response data. Default is `JSONDecoder()`.
    ///   - queue: The dispatch queue to receive the response on. Default is `.main`.
    /// - Returns: A publisher that emits the decoded response data or an error.
    func request<T, Decoder>(
        _ endpoint: Endpoint,
        decodingType: T.Type,
        decoder: Decoder = JSONDecoder(),
        queue: DispatchQueue = .main
    ) -> AnyPublisher<T, Error> where T: Decodable, Decoder: TopLevelDecoder, Decoder.Input == Data {
        request(endpoint, queue: queue)
            .data(type: decodingType, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    /// Performs a network request without expecting any response data.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to request.
    ///   - queue: The dispatch queue to receive the response on. Default is `.main`.
    /// - Returns: A publisher that emits `Void` if the request succeeds or an error if it fails.
    func requestPlain(
        _ endpoint: Endpoint,
        queue: DispatchQueue = .main
    ) -> AnyPublisher<Void, Error> {
        request(endpoint, queue: queue)
            .plain()
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
    ) -> AnyPublisher<URL, Error> {
        guard let urlRequest = endpoint.urlRequest else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        logger?.logRequest(urlRequest)
        
        return session.downloadTaskPublisher(for: urlRequest)
            .handleEvents(receiveOutput: { [weak self] output in
                self?.logger?.logResponse(output.response, data: nil)
            })
            .map { $0.url }
            .receive(on: queue)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

public enum APIServices {
    
}

