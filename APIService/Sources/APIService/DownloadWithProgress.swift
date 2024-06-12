import Foundation
import Combine

public protocol DownloadWithProgress {
    var downloadSession: URLSession { get }
    var downloadTaskHandler: DownloadTaskHandler { get }
}

public extension APIService where Self: DownloadWithProgress {
    func downloadTaskPublisher(for url: URL, delegate: DownloadTaskHandler) -> DownloadTaskPublisher {
        self.downloadTaskPublisher(for: .init(url: url), delegate: delegate)
    }
    
    func downloadTaskPublisher(for request: URLRequest, delegate: DownloadTaskHandler) -> DownloadTaskPublisher {
        .init(request: request, session: self.downloadSession, delegate: delegate)
    }
    
    func download(
        _ endpoint: Endpoint,
        queue: DispatchQueue = .main
    ) -> AnyPublisher<(url: URL?, progress: Double?), Error> {
        guard let urlRequest = endpoint.urlRequest else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
    
        return downloadTaskPublisher(for: urlRequest, delegate: downloadTaskHandler)
            .mapError { $0 as Error }
            .receive(on: queue)
            .eraseToAnyPublisher()
    }
}

public class DownloadTaskHandler: NSObject, URLSessionDownloadDelegate {
    var didFinishDownloading: ((_ requestURL: URL, _ location: URL) -> Void)?
    var didWriteData: ((_ requestURL: URL, _ bytesWritten: Int64, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)?
    var didResume: ((_ requestURL: URL, _ fileOffset: Int64, _ expectedTotalBytes: Int64) -> Void)?
    var didComplete: ((_ requestURL: URL, _ error: Error?) -> Void)?
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url else { return }
        didFinishDownloading?(url, location)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.originalRequest?.url else { return }
        didWriteData?(url, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("resume")
        guard let url = downloadTask.originalRequest?.url else { return }
        didResume?(url, fileOffset, expectedTotalBytes)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url else { return }
        didComplete?(url, error)
    }
}

public struct DownloadTaskPublisher: Publisher {
    
    public typealias Output = (url: URL?, progress: Double?)
    public typealias Failure = URLError
    
    private let request: URLRequest
    private let session: URLSession
    private unowned let delegate: DownloadTaskHandler
    
    public init(request: URLRequest, session: URLSession, delegate: DownloadTaskHandler) {
        self.request = request
        self.session = session
        self.delegate = delegate
    }
    
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

public class DownloadTaskSubscription<SubscriberType: Subscriber>: NSObject, Subscription where
    SubscriberType.Input == (url: URL?, progress: Double?),
    SubscriberType.Failure == URLError
{
    private var subscriber: SubscriberType?
    private weak var session: URLSession!
    private var request: URLRequest!
    private var task: URLSessionDownloadTask!
    private unowned let delegate: DownloadTaskHandler
    
    public init(subscriber: SubscriberType, session: URLSession, request: URLRequest, delegate: DownloadTaskHandler) {
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
        
        delegate.didFinishDownloading = { [weak self] url, location in
            guard url == requestURL else { return }
            do {
                let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let fileUrl = cacheDir.appendingPathComponent((UUID().uuidString))
                try FileManager.default.moveItem(atPath: location.path, toPath: fileUrl.path)
                _ = self?.subscriber?.receive((url: fileUrl, progress: 1.0))
                self?.subscriber?.receive(completion: .finished)
            }
            catch {
                self?.subscriber?.receive(completion: .failure(URLError(.cannotCreateFile)))
            }
        }
        
        delegate.didComplete = { [weak self] url, error in
            guard url == requestURL else { return }
            
            if let error = error as? URLError {
                self?.subscriber?.receive(completion: .failure(error))
            }
//            else {
//                self?.subscriber?.receive(completion: .finished)
//            }
        }
        
        delegate.didWriteData = { [weak self] url, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
            guard url == requestURL else { return }
            print("Receive", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            _ = self?.subscriber?.receive((nil, progress))
        }
        
        self.task = self.session.downloadTask(with: request)
        self.task.resume()
    }
    
    public func cancel() {
        self.task.cancel()
    }
}
