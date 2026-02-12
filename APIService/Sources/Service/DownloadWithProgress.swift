import Foundation
import Combine

/// Protocol that provides properties for URLSession and DownloadTaskHandler.
public protocol DownloadWithProgress {
    var downloadSession: URLSession { get }
    var downloadTaskHandler: DownloadTaskHandler { get }
}

public extension APIService where Self: DownloadWithProgress {
    /// Creates a DownloadTaskPublisher for the given URLRequest and delegate.
    ///
    /// - Parameters:
    ///   - request: The URLRequest to create the publisher for.
    ///   - delegate: The delegate to handle download task events.
    /// - Returns: A DownloadTaskPublisher instance.
    private func downloadTaskPublisher(for request: URLRequest, delegate: DownloadTaskHandler) -> DownloadTaskPublisher {
        .init(request: request, session: self.downloadSession, delegate: delegate)
    }
    
    /// Performs a download request and returns the file URL along with progress updates.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to request.
    ///   - queue: The dispatch queue to receive the response on. Default is `.main`.
    /// - Returns: A publisher that emits a tuple containing optional file URL and progress or an error.
    func downloadWithProgress(
        _ endpoint: URLRequestConvertible,
        queue: DispatchQueue = .main
    ) -> AnyPublisher<(url: URL?, progress: Double?), Error> {
        guard let urlRequest = endpoint.urlRequest else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        logger?.logRequest(urlRequest)
    
        return downloadTaskPublisher(for: urlRequest, delegate: downloadTaskHandler)
            .mapError { $0 as Error }
            .receive(on: queue)
            .eraseToAnyPublisher()
    }
}

/// Class that handles URLSession download task events.
public class DownloadTaskHandler: NSObject, URLSessionDownloadDelegate {
    /// A closure to be called when the download task finishes downloading.
    public var didFinishDownloading: ((_ requestURL: URL, _ location: URL) -> Void)?
    
    /// A closure to be called when the download task writes data.
    public var didWriteData: ((_ requestURL: URL, _ bytesWritten: Int64, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)?
    
    /// A closure to be called when the download task resumes.
    public var didResume: ((_ requestURL: URL, _ fileOffset: Int64, _ expectedTotalBytes: Int64) -> Void)?
    
    /// A closure to be called when the download task completes.
    public var didComplete: ((_ requestURL: URL, _ error: Error?) -> Void)?
    
    /// An optional logger for logging requests and responses.
    public weak var logger: APILogger?

    private struct TaskCallbacks {
        var didWriteData: ((_ bytesWritten: Int64, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)?
        var didFinishDownloading: ((_ location: URL, _ response: URLResponse?) -> Void)?
        var didComplete: ((_ response: URLResponse?, _ error: Error?) -> Void)?

        static let empty = TaskCallbacks()
    }

    private let lock = NSLock()
    private var taskCallbacks = [Int: TaskCallbacks]()
    
    /// Initializes a new instance of DownloadTaskHandler with an optional logger.
    ///
    /// - Parameter logger: The logger to use for logging requests and responses. Default is `CompactLogger.shared`.
    public init(logger: APILogger? = CompactLogger.shared) {
        self.logger = logger
        super.init()
    }

    func registerCallbacks(
        for taskIdentifier: Int,
        didWriteData: ((_ bytesWritten: Int64, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)? = nil,
        didFinishDownloading: ((_ location: URL, _ response: URLResponse?) -> Void)? = nil,
        didComplete: ((_ response: URLResponse?, _ error: Error?) -> Void)? = nil
    ) {
        lock.lock()
        defer { lock.unlock() }
        taskCallbacks[taskIdentifier] = TaskCallbacks(
            didWriteData: didWriteData,
            didFinishDownloading: didFinishDownloading,
            didComplete: didComplete
        )
    }

    func unregisterCallbacks(for taskIdentifier: Int) {
        lock.lock()
        defer { lock.unlock() }
        taskCallbacks[taskIdentifier] = nil
    }

    private func callbacks(for taskIdentifier: Int) -> TaskCallbacks {
        lock.lock()
        defer { lock.unlock() }
        return taskCallbacks[taskIdentifier] ?? .empty
    }

    private func takeCallbacks(for taskIdentifier: Int) -> TaskCallbacks {
        lock.lock()
        defer { lock.unlock() }
        return taskCallbacks.removeValue(forKey: taskIdentifier) ?? .empty
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url else { return }
        logger?.logResponse(forRequest: downloadTask.originalRequest, response: downloadTask.response, data: nil)
        callbacks(for: downloadTask.taskIdentifier).didFinishDownloading?(location, downloadTask.response)
        didFinishDownloading?(url, location)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.originalRequest?.url else { return }
        callbacks(for: downloadTask.taskIdentifier).didWriteData?(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
        didWriteData?(url, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        guard let url = downloadTask.originalRequest?.url else { return }
        didResume?(url, fileOffset, expectedTotalBytes)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url else { return }
        let callbacks = takeCallbacks(for: task.taskIdentifier)
        let normalizedError = (error as? URLError) ?? error
        callbacks.didComplete?(task.response, normalizedError)
        didComplete?(url, normalizedError)
    }
}

/// A publisher that handles URLSession download tasks and emits file URL and progress updates.
public struct DownloadTaskPublisher: Publisher {
    
    public typealias Output = (url: URL?, progress: Double?)
    public typealias Failure = URLError
    
    private let request: URLRequest
    private let session: URLSession
    private unowned let delegate: DownloadTaskHandler
    
    /// Initializes a new DownloadTaskPublisher.
    ///
    /// - Parameters:
    ///   - request: The URLRequest to perform.
    ///   - session: The URLSession to use.
    ///   - delegate: The DownloadTaskHandler to handle download task events.
    public init(request: URLRequest, session: URLSession, delegate: DownloadTaskHandler) {
        self.request = request
        self.session = session
        self.delegate = delegate
    }
    
    /// Attaches the specified subscriber to this publisher.
    ///
    /// - Parameter subscriber: The subscriber to attach to this publisher.
    public func receive<S>(subscriber: S) where S: Subscriber,
                                                DownloadTaskPublisher.Failure == S.Failure,
                                                DownloadTaskPublisher.Output == S.Input
    {
        let subscription = DownloadTaskSubscription(
            subscriber: subscriber,
            session: self.session,
            request: self.request,
            delegate: self.delegate
        )
        
        subscriber.receive(subscription: subscription)
    }
}

/// A subscription that handles URLSession download tasks and provides updates to the subscriber.
public class DownloadTaskSubscription<SubscriberType: Subscriber>: NSObject, Subscription where
    SubscriberType.Input == (url: URL?, progress: Double?),
    SubscriberType.Failure == URLError
{
    private var subscriber: SubscriberType?
    private weak var session: URLSession?
    private let request: URLRequest
    private var task: URLSessionDownloadTask?
    private unowned let delegate: DownloadTaskHandler
    private var isCompleted = false
    
    /// Initializes a new DownloadTaskSubscription.
    ///
    /// - Parameters:
    ///   - subscriber: The subscriber to receive updates.
    ///   - session: The URLSession to use.
    ///   - request: The URLRequest to perform.
    ///   - delegate: The DownloadTaskHandler to handle download task events.
    public init(subscriber: SubscriberType, session: URLSession, request: URLRequest, delegate: DownloadTaskHandler) {
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

        let task = session.downloadTask(with: request)
        self.task = task

        delegate.registerCallbacks(
            for: task.taskIdentifier,
            didWriteData: { [weak self] _, totalBytesWritten, totalBytesExpectedToWrite in
                guard let self, !self.isCompleted else { return }
                let progress: Double? = totalBytesExpectedToWrite > 0
                    ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                    : nil
                _ = self.subscriber?.receive((nil, progress))
            },
            didFinishDownloading: { [weak self] location, response in
                guard let self, !self.isCompleted else { return }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.finish(.failure(URLError(.badServerResponse)))
                    return
                }

                guard 200..<300 ~= httpResponse.statusCode else {
                    self.finish(.failure(URLError(.badServerResponse)))
                    return
                }

                do {
                    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                    let fileUrl = cacheDir.appendingPathComponent(UUID().uuidString)
                    try FileManager.default.moveItem(atPath: location.path, toPath: fileUrl.path)
                    _ = self.subscriber?.receive((url: fileUrl, progress: 1.0))
                    self.finish(.finished)
                } catch {
                    self.finish(.failure(URLError(.cannotCreateFile)))
                }
            },
            didComplete: { [weak self] response, error in
                guard let self, !self.isCompleted else { return }

                if let error {
                    let urlError = (error as? URLError) ?? URLError(.unknown)
                    self.finish(.failure(urlError))
                    return
                }

                if let httpResponse = response as? HTTPURLResponse,
                   !(200..<300 ~= httpResponse.statusCode) {
                    self.finish(.failure(URLError(.badServerResponse)))
                }
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
    
    /// Cancels the subscription, stopping the download task.
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
