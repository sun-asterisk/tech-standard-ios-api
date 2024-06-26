import Foundation
import Combine

public protocol DataWithProgress {
    var dataSession: URLSession { get }
    var dataTaskHandler: DataTaskHandler { get }
}

public extension APIService where Self: DataWithProgress {
    private func dataTaskPublisher(for request: URLRequest, delegate: DataTaskHandler) -> DataTaskPublisher {
        .init(request: request, session: self.dataSession, delegate: delegate)
    }
    
    func requestDataWithProgress(
        _ endpoint: Endpoint,
        queue: DispatchQueue = .main
    ) -> AnyPublisher<(data: Data?, progress: Double?), Error> {
        guard let urlRequest = endpoint.urlRequest else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return dataTaskPublisher(for: urlRequest, delegate: dataTaskHandler)
            .mapError { $0 as Error }
            .receive(on: queue)
            .eraseToAnyPublisher()
    }
}

public class DataTaskHandler: NSObject, URLSessionDataDelegate {
    var didFinishReceiving: ((_ requestURL: URL, _ data: Data) -> Void)?
    var didReceive: ((_ requestURL: URL, _ totalBytesReceived: Int64, _ totalBytesExpectedToReceive: Int64, _ data: Data) -> Void)?
    var didComplete: ((_ requestURL: URL, _ error: Error?) -> Void)?
    
    private var receivedDataDict = [URL: Data]()
    
    private func getReceivedData(for url: URL) -> Data {
        receivedDataDict[url] ?? Data()
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let url = dataTask.originalRequest?.url else { return }
        // Append received data
        var receivedData = getReceivedData(for: url)
        receivedData.append(data)
        receivedDataDict[url] = receivedData
        
        let totalBytesReceived = dataTask.countOfBytesReceived
        let totalBytesExpectedToReceive = dataTask.countOfBytesExpectedToReceive
        didReceive?(url, totalBytesReceived, totalBytesExpectedToReceive, receivedData)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url else { return }
        
        if let error = error as? URLError {
            didComplete?(url, error)
        } else {
            didComplete?(url, nil)
        }
        
        // Clean up
        receivedDataDict[url] = nil
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        completionHandler(proposedResponse)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
}

public struct DataTaskPublisher: Publisher {
    
    public typealias Output = (data: Data?, progress: Double?)
    public typealias Failure = URLError
    
    private let request: URLRequest
    private let session: URLSession
    private unowned let delegate: DataTaskHandler
    
    public init(request: URLRequest, session: URLSession, delegate: DataTaskHandler) {
        self.request = request
        self.session = session
        self.delegate = delegate
    }
    
    public func receive<S>(subscriber: S) where S: Subscriber,
                                                DataTaskPublisher.Failure == S.Failure,
                                                DataTaskPublisher.Output == S.Input
    {
        let subscription = DataTaskSubscription(
            subscriber: subscriber,
            session: self.session,
            request: self.request,
            delegate: self.delegate
        )
        
        subscriber.receive(subscription: subscription)
    }
}

public class DataTaskSubscription<SubscriberType: Subscriber>: NSObject, Subscription where
    SubscriberType.Input == (data: Data?, progress: Double?),
    SubscriberType.Failure == URLError
{
    private var subscriber: SubscriberType?
    private weak var session: URLSession!
    private var request: URLRequest!
    private var task: URLSessionDataTask!
    private unowned let delegate: DataTaskHandler
    
    public init(subscriber: SubscriberType, session: URLSession, request: URLRequest, delegate: DataTaskHandler) {
        self.subscriber = subscriber
        self.session = session
        self.request = request
        self.delegate = delegate
    }
    
    public func request(_ demand: Subscribers.Demand) {
        guard demand > 0 else { return }
        
        guard let requestURL = request.url else {
            subscriber?.receive(completion: .failure(URLError(.badURL)))
            return
        }
        
        delegate.didFinishReceiving = { [weak self] url, data in
            guard url == requestURL else { return }
            _ = self?.subscriber?.receive((data, 1.0))
        }
        
        delegate.didComplete = { [weak self] url, error in
            guard url == requestURL else { return }
            
            if let error = error as? URLError {
                self?.subscriber?.receive(completion: .failure(error))
            } else {
                self?.subscriber?.receive(completion: .finished)
            }
        }
        
        delegate.didReceive = { [weak self] url, totalBytesReceived, totalBytesExpectedToReceive, data in
            guard url == requestURL else { return }
            let progress = Double(totalBytesReceived) / Double(totalBytesExpectedToReceive)
            _ = self?.subscriber?.receive((data, progress))
        }
        
        self.task = self.session.dataTask(with: request)
        self.task.resume()
    }
    
    public func cancel() {
        self.task.cancel()
    }
}
