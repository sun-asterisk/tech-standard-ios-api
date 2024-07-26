import Foundation

/// A namespace for different API services.
public enum APIServices {
    
}

public extension APIServices {
    /// Provides a shared instance of `DefaultAPIService`.
    ///
    /// - Returns: The shared instance of `DefaultAPIService`.
    static var `default`: DefaultAPIService { DefaultAPIService.shared }
}
