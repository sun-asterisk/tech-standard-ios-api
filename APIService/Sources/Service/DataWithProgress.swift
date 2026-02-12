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

    private struct TaskCallbacks {
        var didReceive: ((_ totalBytesReceived: Int64, _ totalBytesExpectedToReceive: Int64, _ data: Data) -> Void)?
        var didComplete: ((_ response: URLResponse?, _ error: Error?) -> Void)?

        static let empty = TaskCallbacks()
    }

    private struct TaskState {
        var callbacks: TaskCallbacks
        var receivedData = Data()
    }

    private let lock = NSLock()
    private var taskStates = [Int: TaskState]()
    
    /// Initializes a new instance of DataTaskHandler with an optional logger.
    ///
    /// - Parameter logger: The logger to use for logging requests and responses. Default is `CompactLogger.shared`.
    public init(logger: APILogger? = CompactLogger.shared) {
        self.logger = logger
        super.init()
    }

    func registerCallbacks(
        for taskIdentifier: Int,
        didReceive: ((_ totalBytesReceived: Int64, _ totalBytesExpectedToReceive: Int64, _ data: Data) -> Void)? = nil,
        didComplete: ((_ response: URLResponse?, _ error: Error?) -> Void)? = nil
    ) {
        lock.lock()
        defer { lock.unlock() }

        var state = taskStates[taskIdentifier] ?? TaskState(callbacks: .empty)
        state.callbacks = TaskCallbacks(didReceive: didReceive, didComplete: didComplete)
        taskStates[taskIdentifier] = state
    }

    func unregisterCallbacks(for taskIdentifier: Int) {
        lock.lock()
        defer { lock.unlock() }
        taskStates[taskIdentifier] = nil
    }

    private func appendData(_ data: Data, for taskIdentifier: Int) -> TaskState {
        lock.lock()
        defer { lock.unlock() }

        var state = taskStates[taskIdentifier] ?? TaskState(callbacks: .empty)
        state.receivedData.append(data)
        taskStates[taskIdentifier] = state
        return state
    }

    private func takeState(for taskIdentifier: Int) -> TaskState? {
        lock.lock()
        defer { lock.unlock() }
        return taskStates.removeValue(forKey: taskIdentifier)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let url = dataTask.originalRequest?.url else { return }
        let state = appendData(data, for: dataTask.taskIdentifier)
        let receivedData = state.receivedData
        
        let totalBytesReceived = dataTask.countOfBytesReceived
        let totalBytesExpectedToReceive = dataTask.countOfBytesExpectedToReceive
        state.callbacks.didReceive?(totalBytesReceived, totalBytesExpectedToReceive, receivedData)
        didReceive?(url, totalBytesReceived, totalBytesExpectedToReceive, receivedData)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let state = takeState(for: task.taskIdentifier)
        let normalizedError = (error as? URLError) ?? error
        
        logger?.logResponse(forRequest: task.originalRequest, response: task.response, data: nil)

        state?.callbacks.didComplete?(task.response, normalizedError)

        if let url = task.originalRequest?.url {
            if normalizedError == nil, let data = state?.receivedData {
                didFinishReceiving?(url, data)
            }
            didComplete?(url, normalizedError)
        }
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
    private weak var session: URLSession?
    private let request: URLRequest
    private var task: URLSessionDataTask?
    private unowned let delegate: DataTaskHandler
    private var isCompleted = false
    
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
        guard demand > 0, !isCompleted else { return }
        guard request.url != nil else {
            finish(.failure(URLError(.badURL)))
            return
        }
        guard let session else {
            finish(.failure(URLError(.unknown)))
            return
        }

        let task = session.dataTask(with: request)
        self.task = task

        delegate.registerCallbacks(
            for: task.taskIdentifier,
            didReceive: { [weak self] totalBytesReceived, totalBytesExpectedToReceive, data in
                guard let self, !self.isCompleted else { return }
                let progress: Double? = totalBytesExpectedToReceive > 0
                    ? Double(totalBytesReceived) / Double(totalBytesExpectedToReceive)
                    : nil
                _ = self.subscriber?.receive((data, progress))
            },
            didComplete: { [weak self] response, error in
                guard let self, !self.isCompleted else { return }

                if let error {
                    let urlError = (error as? URLError) ?? URLError(.unknown)
                    self.finish(.failure(urlError))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.finish(.failure(URLError(.badServerResponse)))
                    return
                }

                guard 200..<300 ~= httpResponse.statusCode else {
                    self.finish(.failure(URLError(.badServerResponse)))
                    return
                }

                self.finish(.finished)
            }
        )

        task.resume()
    }

    private func finish(_ completion: Subscribers.Completion<URLError>) {
        guard !isCompleted else { return }
        isCompleted = true

        if let task {
            delegate.unregisterCallbacks(for: task.taskIdentifier)
        }

        subscriber?.receive(completion: completion)
        subscriber = nil
        task = nil
    }
    
    /// Cancels the subscription, stopping the data task.
    public func cancel() {
        guard !isCompleted else { return }
        isCompleted = true

        if let task {
            delegate.unregisterCallbacks(for: task.taskIdentifier)
            task.cancel()
        }

        subscriber = nil
        task = nil
    }
}
