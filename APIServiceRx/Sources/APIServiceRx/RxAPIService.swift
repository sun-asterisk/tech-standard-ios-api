import Foundation
import APIService
import RxSwift

open class RxAPIService: APIService {
    /// The shared instance of `RxAPIService`.
    nonisolated(unsafe) public static let shared = RxAPIService()
    
    /// The URLSession used for general network requests.
    public let session: URLSession
    
    /// The logger used for logging API requests and responses.
    public var logger: APILogger? = IntermediateLogger.shared
    
    /// Private initializer to ensure singleton usage.
    private init() {
        // Session for request
        self.session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
    }
}

public extension APIServices {
    /// Provides access to a shared instance of `RxAPIService` for performing API requests using RxSwift.
    ///
    /// - Returns: A shared instance of `RxAPIService`.
    static var rxSwift: RxAPIService { RxAPIService.shared }
}
