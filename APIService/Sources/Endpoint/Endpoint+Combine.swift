import Combine

public extension Endpoint {
    /// Returns a publisher that emits the endpoint.
    ///
    /// - Returns: A publisher that emits the endpoint.
    var publisher: AnyPublisher<Endpoint, Never> {
        Just(self).eraseToAnyPublisher()
    }
}
