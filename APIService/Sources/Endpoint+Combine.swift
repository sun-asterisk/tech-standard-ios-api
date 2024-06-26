import Combine

public extension Endpoint {
    var publisher: AnyPublisher<Endpoint, Never> {
        Just(self).eraseToAnyPublisher()
    }
}
