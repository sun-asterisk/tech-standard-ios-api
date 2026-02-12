import Testing
import Foundation
import Combine
@testable import APIService

private final class StubURLProtocol: URLProtocol {
    typealias ResponseBuilder = (URLRequest) throws -> (HTTPURLResponse, Data, TimeInterval)
    static var responseBuilder: ResponseBuilder?

    private var isStopped = false

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let responseBuilder = Self.responseBuilder else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data, delay) = try responseBuilder(request)
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, !self.isStopped, let client = self.client else { return }
                client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                if !data.isEmpty {
                    client.urlProtocol(self, didLoad: data)
                }
                client.urlProtocolDidFinishLoading(self)
            }
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        isStopped = true
    }
}

private final class MockProgressAPIService: APIService, DataWithProgress {
    let session: URLSession
    let dataSession: URLSession
    let dataTaskHandler: DataTaskHandler
    var logger: APILogger?

    init(configuration: URLSessionConfiguration) {
        self.session = URLSession(configuration: configuration)
        self.dataTaskHandler = DataTaskHandler(logger: nil)
        self.dataSession = URLSession(configuration: configuration, delegate: dataTaskHandler, delegateQueue: nil)
        self.logger = nil
    }
}

@Suite(.serialized)
struct ProgressServiceTests {
    @Test("requestDataWithProgress fails on non-2xx response")
    func requestDataWithProgressFailsOnNon2xx() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]

        StubURLProtocol.responseBuilder = { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("error".utf8), 0.0)
        }
        defer { StubURLProtocol.responseBuilder = nil }

        let service = MockProgressAPIService(configuration: config)
        let expectation = DispatchSemaphore(value: 0)

        var completion: Subscribers.Completion<Error>?
        var cancellable: AnyCancellable?
        cancellable = service.requestDataWithProgress("https://example.com/fail", queue: .global())
            .sink(receiveCompletion: { result in
                completion = result
                expectation.signal()
            }, receiveValue: { _ in })

        let waitResult = expectation.wait(timeout: .now() + 2.0)
        #expect(waitResult == .success)
        #expect(cancellable != nil)

        switch completion {
        case .failure(let error):
            let urlError = error as? URLError
            #expect(urlError?.code == .badServerResponse)
        default:
            Issue.record("Expected failure completion for non-2xx response")
        }
    }

    @Test("requestDataWithProgress supports concurrent requests to same URL")
    func requestDataWithProgressSupportsConcurrentRequestsToSameURL() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]

        StubURLProtocol.responseBuilder = { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let requestID = request.value(forHTTPHeaderField: "X-Request-ID") ?? "unknown"
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let payload = Data("payload-\(requestID)".utf8)
            let delay: TimeInterval = requestID == "1" ? 0.15 : 0.0
            return (response, payload, delay)
        }
        defer { StubURLProtocol.responseBuilder = nil }

        let service = MockProgressAPIService(configuration: config)

        var request1 = URLRequest(url: URL(string: "https://example.com/shared")!)
        request1.setValue("1", forHTTPHeaderField: "X-Request-ID")
        var request2 = URLRequest(url: URL(string: "https://example.com/shared")!)
        request2.setValue("2", forHTTPHeaderField: "X-Request-ID")

        var values1 = [(data: Data?, progress: Double?)]()
        var values2 = [(data: Data?, progress: Double?)]()
        var completion1: Subscribers.Completion<Error>?
        var completion2: Subscribers.Completion<Error>?

        let expectation = DispatchSemaphore(value: 0)

        let cancellable1 = service.requestDataWithProgress(request1, queue: .global())
            .sink(receiveCompletion: { result in
                completion1 = result
                expectation.signal()
            }, receiveValue: { output in
                values1.append(output)
            })

        let cancellable2 = service.requestDataWithProgress(request2, queue: .global())
            .sink(receiveCompletion: { result in
                completion2 = result
                expectation.signal()
            }, receiveValue: { output in
                values2.append(output)
            })

        let wait1 = expectation.wait(timeout: .now() + 3.0)
        let wait2 = expectation.wait(timeout: .now() + 3.0)
        #expect(wait1 == .success)
        #expect(wait2 == .success)

        switch completion1 {
        case .finished:
            break
        default:
            Issue.record("First request did not finish successfully")
        }

        switch completion2 {
        case .finished:
            break
        default:
            Issue.record("Second request did not finish successfully")
        }

        let payload1 = values1.last?.data.flatMap { String(data: $0, encoding: .utf8) }
        let payload2 = values2.last?.data.flatMap { String(data: $0, encoding: .utf8) }
        #expect(payload1 == "payload-1")
        #expect(payload2 == "payload-2")

        withExtendedLifetime((cancellable1, cancellable2)) {}
    }
}
