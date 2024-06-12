import Foundation

public final class DefaultAPIService: APIService, DownloadWithProgress {
    public static let shared = DefaultAPIService()
    public let session: URLSession
    public var downloadTaskHandler = DownloadTaskHandler()
    public var downloadSession: URLSession { session }
    
    private init() {
        // Session for downloading
        let configuration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration

        // Adjust the timeout interval for requests and resources
        configuration.timeoutIntervalForRequest = 30.0  // 30 seconds for request timeout
        configuration.timeoutIntervalForResource = 60.0  // 60 seconds for resource timeout

        // Set the maximum number of simultaneous connections to a host
        configuration.httpMaximumConnectionsPerHost = 5

        // Allow cellular access if needed
        configuration.allowsCellularAccess = true  // Set to false if you want to restrict to Wi-Fi

        // Enable discretionary downloading
        configuration.isDiscretionary = true

        // Create a URLSession with the configured settings
        self.session = URLSession(configuration: configuration, delegate: downloadTaskHandler, delegateQueue: nil)
    }
}
