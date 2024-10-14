import Foundation
import APIService
import RxSwift
import Combine

public extension APIService {
    /// Performs a network request and returns an Observable emitting the raw response and data.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to request.
    ///   - queue: The dispatch queue to receive the response on. Default is `.main`.
    /// - Returns: An observable that emits a tuple containing the URLResponse and the response Data, or an error.
    func request(
        _ endpoint: URLRequestConvertible,
        queue: DispatchQueue = .main
    ) -> Observable<(response: URLSession.DataTaskPublisher.Output, data: Data)> {
        return Observable.create { [weak self] observer in
            guard let self else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            let cancellable = self.request(endpoint, queue: queue)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        observer.onError(error)
                    case .finished:
                        observer.onCompleted()
                    }
                }, receiveValue: { output in
                    observer.onNext((response: output, data: output.data))
                })
            
            return Disposables.create {
                cancellable.cancel()
            }
        }
    }
}

public extension ObservableType where Element == URLSession.DataTaskPublisher.Output {
    /// Transforms the observable to decode the data into a specified type.
    ///
    /// - Parameters:
    ///   - type: The type to decode the data into.
    ///   - decoder: The decoder to use for decoding the data. Defaults to `JSONDecoder`.
    /// - Returns: An observable that emits the decoded type or an error.
    func data<T, Decoder>(
        type: T.Type,
        decoder: Decoder = JSONDecoder()
    ) -> Observable<T> where T: Decodable, Decoder: TopLevelDecoder, Decoder.Input == Data {
        map { $0.data }
            .map { data in
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw error
                }
            }
    }
    
    /// Transforms the observable to emit only the raw data.
    ///
    /// - Returns: An observable that emits the data or an error.
    func data() -> Observable<Data> {
        map { $0.data }
    }
    
    /// Transforms the observable to emit a `Void` value, effectively ignoring the data.
    ///
    /// - Returns: An observable that emits `Void` or an error.
    func plain() -> Observable<Void> {
        map { _ in () }
    }
    
    /// Transforms the observable to emit a JSON object as a dictionary.
    ///
    /// - Returns: An observable that emits a dictionary representing the JSON or `nil`, or an error.
    func json() -> Observable<[String: Any]?> {
        map { $0.data.toJSON() }
    }
}
