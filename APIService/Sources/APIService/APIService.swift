import Foundation
import Combine
import UIKit

public protocol APIService {
    var session: URLSession { get }
}

public protocol DownloadWithProgress {
    var progressHandler: ProgressHandler { get }
}

public extension DownloadWithProgress {
    func addProgressPublisher(for url: URL, queue: DispatchQueue) -> AnyPublisher<(Double, Data?), URLError> {
        progressHandler.addProgressPublisher(for: url)
            .receive(on: queue)
            .eraseToAnyPublisher()
    }
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
    
    func download(
        _ endpoint: Endpoint,
        queue: DispatchQueue = .main
    ) -> AnyPublisher<URL, Error> {
        guard let urlRequest = endpoint.urlRequest else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
    
        return session.downloadTaskPublisher(for: urlRequest)
            .map { $0.url }
            .mapError { $0 as Error }
            .receive(on: queue)
            .eraseToAnyPublisher()
    }
    
    func download(
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

public extension APIService where Self: DownloadWithProgress {
    func download(
        _ endpoint: Endpoint,
        queue: DispatchQueue = .main
    ) -> AnyPublisher<(Double, Data?), URLError> {
        guard let urlRequest = endpoint.urlRequest, let url = urlRequest.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        defer {
            let datatask = session.dataTask(with: url)
            datatask.resume()
        }
        
        return addProgressPublisher(for: url, queue: queue)
    }
}

public final class DefaultAPIService: APIService, DownloadWithProgress {
    public static let shared = DefaultAPIService()
    public let session: URLSession
    public var progressHandler = ProgressHandler()
    
    private init() {
        self.session = URLSession(configuration: .default, delegate: progressHandler, delegateQueue: nil)
    }
}

public class ProgressHandler: NSObject, URLSessionDataDelegate {
    var progressPublishers = [URL: PassthroughSubject<(Double, Data?), URLError>]()
    var receivedData = Data()
    
    func addProgressPublisher(for url: URL) -> PassthroughSubject<(Double, Data?), URLError> {
        let publisher = PassthroughSubject<(Double, Data?), URLError>()
        progressPublishers[url] = publisher
        return publisher
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Append received data
        receivedData.append(data)
        print("Received data: \(data)")
        
        guard let url = dataTask.originalRequest?.url else { return }
        let receivedBytes = Double(dataTask.countOfBytesReceived)
        let totalBytes = Double(dataTask.countOfBytesExpectedToReceive)
        let progress = receivedBytes / totalBytes
        progressPublishers[url]?.send((progress, nil))
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url else { return }
        if let error = error as? URLError {
            progressPublishers[url]?.send(completion: .failure(error))
        } else {
            progressPublishers[url]?.send((1.0, receivedData))
            progressPublishers[url]?.send(completion: .finished)
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        print("Data task became a download task")
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        completionHandler(proposedResponse)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
}
