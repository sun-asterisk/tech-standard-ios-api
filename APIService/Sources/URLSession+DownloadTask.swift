import Foundation
import Combine

public extension URLSession {
    /// Returns a download task publisher for the given URL.
    ///
    /// - Parameter url: The URL to create the download task for.
    /// - Returns: A `DownloadTaskPublisher` instance.
    func downloadTaskPublisher(for url: URL) -> URLSession.DownloadTaskPublisher {
        self.downloadTaskPublisher(for: .init(url: url))
    }
    
    /// Returns a download task publisher for the given URLRequest.
    ///
    /// - Parameter request: The URLRequest to create the download task for.
    /// - Returns: A `DownloadTaskPublisher` instance.
    func downloadTaskPublisher(for request: URLRequest) -> URLSession.DownloadTaskPublisher {
        .init(request: request, session: self)
    }
    
    /// A publisher that handles URLSession download tasks and emits the file URL and response.
    struct DownloadTaskPublisher: Publisher {
        
        public typealias Output = (url: URL, response: URLResponse)
        public typealias Failure = URLError
        
        public let request: URLRequest
        public let session: URLSession
        
        /// Initializes a new DownloadTaskPublisher.
        ///
        /// - Parameters:
        ///   - request: The URLRequest to perform.
        ///   - session: The URLSession to use.
        public init(request: URLRequest, session: URLSession) {
            self.request = request
            self.session = session
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
                request: self.request
            )
            
            subscriber.receive(subscription: subscription)
        }
    }

    /// A subscription that handles URLSession download tasks and provides updates to the subscriber.
    final class DownloadTaskSubscription<SubscriberType: Subscriber>: NSObject, Subscription where
        SubscriberType.Input == (url: URL, response: URLResponse),
        SubscriberType.Failure == URLError
    {
        private var subscriber: SubscriberType?
        private weak var session: URLSession!
        private var request: URLRequest!
        private var task: URLSessionDownloadTask!

        /// Initializes a new DownloadTaskSubscription.
        ///
        /// - Parameters:
        ///   - subscriber: The subscriber to receive updates.
        ///   - session: The URLSession to use.
        ///   - request: The URLRequest to perform.
        public init(subscriber: SubscriberType, session: URLSession, request: URLRequest) {
            self.subscriber = subscriber
            self.session = session
            self.request = request
        }

        /// Requests the publisher to begin sending values.
        ///
        /// - Parameter demand: The number of values to request.
        public func request(_ demand: Subscribers.Demand) {
            guard demand > 0 else {
                return
            }
            
            self.task = self.session.downloadTask(with: request) { [weak self] url, response, error in
                if let error = error as? URLError {
                    self?.subscriber?.receive(completion: .failure(error))
                    return
                }
                guard let response = response else {
                    self?.subscriber?.receive(completion: .failure(URLError(.badServerResponse)))
                    return
                }
                guard let url = url else {
                    self?.subscriber?.receive(completion: .failure(URLError(.badURL)))
                    return
                }
                do {
                    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                    let fileUrl = cacheDir.appendingPathComponent((UUID().uuidString))
                    try FileManager.default.moveItem(atPath: url.path, toPath: fileUrl.path)
                    _ = self?.subscriber?.receive((url: fileUrl, response: response))
                    self?.subscriber?.receive(completion: .finished)
                } catch {
                    self?.subscriber?.receive(completion: .failure(URLError(.cannotCreateFile)))
                }
            }
            
            self.task.resume()
        }

        /// Cancels the subscription, stopping the download task.
        public func cancel() {
            self.task.cancel()
        }
    }
}
