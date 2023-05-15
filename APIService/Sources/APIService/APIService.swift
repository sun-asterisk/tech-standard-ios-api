import Foundation
import Combine

public protocol APIService {
    var session: URLSession { get }
}

public extension APIService {
    func request<T, Decoder>(
        _ endpoint: Endpoint,
        decodingType: T.Type,
        decoder: Decoder = JSONDecoder(),
        queue: DispatchQueue = .main,
        retries: Int = 0
    ) -> AnyPublisher<T, Error> where T: Decodable, Decoder: TopLevelDecoder, Decoder.Input == Data {
        guard let urlRequest = endpoint.urlRequest else {
            return Fail(error: APIError.invalidRequest).eraseToAnyPublisher()
        }
    
        return session.dataTaskPublisher(for: urlRequest)
            .tryMap {
                guard let response = $0.response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw APIError.responseUnsuccessful
                }
                return $0.data
            }
            .decode(type: T.self, decoder: decoder)
            .receive(on: queue)
            .retry(retries)
            .eraseToAnyPublisher()
    }
}

public final class DefaultAPIService: APIService {
    public static let shared = DefaultAPIService()
    public let session: URLSession
    
    private init() {
        self.session = URLSession(configuration: .default)
    }
}

