import Foundation
import Combine

/// Protocol that provides properties for URLSession and DataTaskHandler.
public protocol DataWithProgress {
    var dataSession: URLSession { get }
    var dataTaskHandler: DataTaskHandler { get }
}

public extension APIService where Self: DataWithProgress {
    /// Creates a DataTaskPublisher for the given URLRequest and delegate.
    ///
    /// - Parameters:
    ///   - request: The URLRequest to create the publisher for.
    ///   - delegate: The delegate to handle data task events.
    /// - Returns: A DataTaskPublisher instance.
    private func dataTaskPublisher(for request: URLRequest, delegate: DataTaskHandler) -> DataTaskPublisher {
        .init(request: request, session: self.dataSession, delegate: delegate)
    }
    
    /// Performs a network request and returns the data along with progress updates.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to request.
    ///   - queue: The dispatch queue to receive the response on. Default is `.main`.
    /// - Returns: A publisher that emits a tuple containing optional data and progress or an error.
    func requestDataWithProgress(
        _ endpoint: URLRequestConvertible,
        queue: DispatchQueue = .main
    ) -> AnyPublisher<(data: Data?, progress: Double?), Error> {
        guard let urlRequest = endpoint.urlRequest else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        logger?.logRequest(urlRequest)
        
        return dataTaskPublisher(for: urlRequest, delegate: dataTaskHandler)
            .mapError { $0 as Error }
            .receive(on: queue)
            .eraseToAnyPublisher()
    }
}

/// Class that handles URLSession data task events.
public class DataTaskHandler: NSObject, URLSessionDataDelegate {
    /// A closure to be called when data has finished receiving.
    public var didFinishReceiving: ((_ requestURL: URL, _ data: Data) -> Void)?
    
    /// A closure to be called when data is received.
    public var didReceive: ((_ requestURL: URL, _ totalBytesReceived: Int64, _ totalBytesExpectedToReceive: Int64, _ data: Data) -> Void)?
    
    /// A closure to be called when the data task completes.
    public var didComplete: ((_ requestURL: URL, _ error: Error?) -> Void)?
    
    /// An optional logger for logging requests and responses.
    public weak var logger: APILogger?
    
    /// A dictionary to store received data for each URL.
    private var receivedDataDict = [URL: Data]()
    
    /// Initializes a new instance of DataTaskHandler with an optional logger.
    ///
    /// - Parameter logger: The logger to use for logging requests and responses. Default is `CompactLogger.shared`.
    public init(logger: APILogger? = CompactLogger.shared) {
        self.logger = logger
        super.init()
    }
    
    /// Gets the received data for the given URL.
    ///
    /// - Parameter url: The URL to get the received data for.
    /// - Returns: The received data.
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
        
        logger?.logResponse(task.response, data: nil)
        
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

/// A publisher that handles URLSession data tasks and emits data and progress updates.
public struct DataTaskPublisher: Publisher {
    
    public typealias Output = (data: Data?, progress: Double?)
    public typealias Failure = URLError
    
    private let request: URLRequest
    private let session: URLSession
    private unowned let delegate: DataTaskHandler
    
    /// Initializes a new DataTaskPublisher.
    ///
    /// - Parameters:
    ///   - request: The URLRequest to perform.
    ///   - session: The URLSession to use.
    ///   - delegate: The DataTaskHandler to handle data task events.
    public init(request: URLRequest, session: URLSession, delegate: DataTaskHandler) {
        self.request = request
        self.session = session
        self.delegate = delegate
    }
    
    /// Attaches the specified subscriber to this publisher.
    ///
    /// - Parameter subscriber: The subscriber to attach to this publisher.
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

/// A subscription that handles URLSession data tasks and provides updates to the subscriber.
public class DataTaskSubscription<SubscriberType: Subscriber>: NSObject, Subscription where
    SubscriberType.Input == (data: Data?, progress: Double?),
    SubscriberType.Failure == URLError
{
    private var subscriber: SubscriberType?
    private weak var session: URLSession!
    private var request: URLRequest!
    private var task: URLSessionDataTask!
    private unowned let delegate: DataTaskHandler
    
    /// Initializes a new DataTaskSubscription.
    ///
    /// - Parameters:
    ///   - subscriber: The subscriber to receive updates.
    ///   - session: The URLSession to use.
    ///   - request: The URLRequest to perform.
    ///   - delegate: The DataTaskHandler to handle data task events.
    public init(subscriber: SubscriberType, session: URLSession, request: URLRequest, delegate: DataTaskHandler) {
        self.subscriber = subscriber
        self.session = session
        self.request = request
        self.delegate = delegate
    }
    
    /// Requests the publisher to begin sending values.
    ///
    /// - Parameter demand: The number of values to request.
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
    
    /// Cancels the subscription, stopping the data task.
    public func cancel() {
        self.task.cancel()
    }
}
