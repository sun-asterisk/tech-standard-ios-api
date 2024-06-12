import Foundation
import Combine

public extension URLSession {
    
    func downloadTaskPublisher(for url: URL, delegate: URLSessionDataDelegate) -> URLSession.DownloadTaskPublisher {
        self.downloadTaskPublisher(for: .init(url: url), delegate: delegate)
    }
    
    func downloadTaskPublisher(for request: URLRequest, delegate: URLSessionDataDelegate) -> URLSession.DownloadTaskPublisher {
        .init(request: request, session: self, delegate: delegate)
    }
    
    struct DownloadTaskPublisher: Publisher {
        
        public typealias Output = (url: URL, response: URLResponse)
        public typealias Failure = URLError
        
        public let request: URLRequest
        public let session: URLSession
        
        public init(request: URLRequest, session: URLSession, delegate: URLSessionDataDelegate) {
            self.request = request
            self.session = session
        }
        
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

    final class DownloadTaskSubscription<SubscriberType: Subscriber>: NSObject, Subscription where
        SubscriberType.Input == (url: URL, response: URLResponse),
        SubscriberType.Failure == URLError
    {
        private var subscriber: SubscriberType?
        private weak var session: URLSession!
        private var request: URLRequest!
        private var task: URLSessionDownloadTask!

        public init(subscriber: SubscriberType, session: URLSession, request: URLRequest) {
            self.subscriber = subscriber
            self.session = session
            self.request = request
        }

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
                }
                catch {
                    self?.subscriber?.receive(completion: .failure(URLError(.cannotCreateFile)))
                }
            }
            
            self.task.resume()
        }

        public func cancel() {
            self.task.cancel()
        }
    }
}
