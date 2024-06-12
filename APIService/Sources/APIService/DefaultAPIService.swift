import Foundation

public final class DefaultAPIService: APIService, DownloadWithProgress, DataWithProgress {
    public static let shared = DefaultAPIService()
    public let session: URLSession
    
    // DownloadWithProgress
    public var downloadSession: URLSession
    public var downloadTaskHandler = DownloadTaskHandler()
    
    // DataWithProgress
    public var dataSession: URLSession
    public var dataTaskHandler = DataTaskHandler()
    
    private init() {
        // Session for request
        self.session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        
        // Session for downloading
        let downloadConfiguration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
        downloadConfiguration.timeoutIntervalForRequest = 30.0  // 30 seconds for request timeout
        downloadConfiguration.timeoutIntervalForResource = 60.0  // 60 seconds for resource timeout
        // Set the maximum number of simultaneous connections to a host
        downloadConfiguration.httpMaximumConnectionsPerHost = 5
        // Allow cellular access if needed
        downloadConfiguration.allowsCellularAccess = true  // Set to false if you want to restrict to Wi-Fi
        // Enable discretionary downloading
        downloadConfiguration.isDiscretionary = true
        // Create a URLSession with the configured settings
        self.downloadSession = URLSession(configuration: downloadConfiguration, delegate: downloadTaskHandler, delegateQueue: nil)
        
        // Session for data
        let dataConfiguration = downloadConfiguration.copy() as! URLSessionConfiguration
        self.dataSession = URLSession(configuration: dataConfiguration, delegate: dataTaskHandler, delegateQueue: nil)
    }
}
