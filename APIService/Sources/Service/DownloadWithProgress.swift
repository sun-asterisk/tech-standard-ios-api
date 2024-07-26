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
    
    /// Initializes a new instance of DownloadTaskHandler with an optional logger.
    ///
    /// - Parameter logger: The logger to use for logging requests and responses. Default is `CompactLogger.shared`.
    public init(logger: APILogger? = CompactLogger.shared) {
        self.logger = logger
        super.init()
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url else { return }
        logger?.logResponse(downloadTask.response, data: nil)
        didFinishDownloading?(url, location)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.originalRequest?.url else { return }
        didWriteData?(url, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        guard let url = downloadTask.originalRequest?.url else { return }
        didResume?(url, fileOffset, expectedTotalBytes)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url else { return }
        didComplete?(url, error)
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
    private weak var session: URLSession!
    private var request: URLRequest!
    private var task: URLSessionDownloadTask!
    private unowned let delegate: DownloadTaskHandler
    
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
        guard demand > 0 else { return }
        
        guard let requestURL = request.url else {
            subscriber?.receive(completion: .failure(URLError(.badURL)))
            return
        }
        
        delegate.didFinishDownloading = { [weak self] url, location in
            guard url == requestURL else { return }
            do {
                let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let fileUrl = cacheDir.appendingPathComponent((UUID().uuidString))
                try FileManager.default.moveItem(atPath: location.path, toPath: fileUrl.path)
                _ = self?.subscriber?.receive((url: fileUrl, progress: 1.0))
                self?.subscriber?.receive(completion: .finished)
            } catch {
                self?.subscriber?.receive(completion: .failure(URLError(.cannotCreateFile)))
            }
        }
        
        delegate.didComplete = { [weak self] url, error in
            guard url == requestURL else { return }
            
            if let error = error as? URLError {
                self?.subscriber?.receive(completion: .failure(error))
            }
        }
        
        delegate.didWriteData = { [weak self] url, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
            guard url == requestURL else { return }
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            _ = self?.subscriber?.receive((nil, progress))
        }
        
        self.task = self.session.downloadTask(with: request)
        self.task.resume()
    }
    
    /// Cancels the subscription, stopping the download task.
    public func cancel() {
        self.task.cancel()
    }
}
