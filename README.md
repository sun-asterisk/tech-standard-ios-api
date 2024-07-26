# APIService

APIService is a lightweight and flexible library for making network requests in Swift. It provides a simple interface for defining endpoints, managing network requests, and handling responses with built-in support for logging and progress tracking.

## Installation

To integrate APIService into your Xcode project using Swift Package Manager (SPM), add the following dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/sun-asterisk/tech-standard-ios-api", .upToNextMajor(from: "0.1.0"))
]
```

Then, add `APIService` as a dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["APIService"]
)
```

## Usage

### Defining an Endpoint

Endpoints are defined using the `Endpoint` protocol. You can create custom endpoints by conforming to this protocol or use the provided `BaseEndpoint` for simple use cases.

```swift
struct MyEndpoint: Endpoint {
    var base: String? { "https://api.example.com" }
    var path: String? { "/v1/resource" }
    var httpMethod: HttpMethod { .get }
    var headers: [String: Any]? { ["Authorization": "Bearer token"] }
    var queryItems: [String: Any]? { ["query": "value"] }
    var body: [String: Any]? { nil }
}
```

### Using BaseEndpoint

`BaseEndpoint` is a concrete implementation of `Endpoint` that allows you to easily define endpoints.

```swift
let endpoint = BaseEndpoint(
    base: "https://api.example.com",
    path: "/v1/resource",
    httpMethod: .get,
    headers: ["Authorization": "Bearer token"],
    queryItems: ["query": "value"],
    body: nil
)
```

### Using Enum for Endpoints

You can also define endpoints using enums for better organization.

```swift
enum GitEndpoint {
    case repos(page: Int, perPage: Int)
    case events(url: String, page: Int, perPage: Int)
}

extension GitEndpoint: Endpoint {
    var base: String? {
        "https://api.github.com"
    }
    
    var path: String? {
        switch self {
        case .repos:
            return "/search/repositories"
        default:
            return ""
        }
    }
    
    var urlString: String? {
        switch self {
        case .events(let url, _, _):
            return url
        default:
            return nil
        }
    }
    
    var httpMethod: HttpMethod {
        switch self {
        case .repos:
            return .get
        case .events:
            return .post
        }
    }
    
    var queryItems: [String : Any]? {
        switch self {
        case let .repos(page, perPage):
            return [
                "q": "language:swift",
                "per_page": perPage,
                "page": page
            ]
        case let .events(_, page, perPage):
            return [
                "per_page": perPage,
                "page": page
            ]
        }
    }
}
```

### Using CustomEndpoint

You can customize your endpoints using CustomEndpoint for more flexibility.

```swift
let baseEndpoint = BaseEndpoint(base: "https://api.example.com", path: "/v1/resource")
let customEndpoint = CustomEndpoint(endpoint: baseEndpoint, overrides: .headers(["Authorization": "Bearer token"]))
```

You can also use the extension methods provided by Endpoint to add properties:

```swift
let customizedEndpoint = baseEndpoint
    .add(base: "https://api.newexample.com")
    .add(path: "/v1/newresource")
    .add(httpMethod: .post)
    .add(headers: ["Custom-Header": "Value"])
    .add(queryItems: ["key": "value"])
    .add(body: ["param": "value"])
```

### Using Endpoint Convertible Types

You can create requests using `String`, `URL`, or `URLRequest` by converting them to an `Endpoint` using `toEndpoint()`.

```swift
// Using a String
let urlString = "https://api.example.com/v1/resource"
let endpointFromString = urlString.toEndpoint()

// Using a URL
let url = URL(string: "https://api.example.com/v1/resource")!
let endpointFromURL = url.toEndpoint()

// Using a URLRequest
var urlRequest = URLRequest(url: url)
urlRequest.httpMethod = "GET"
urlRequest.setValue("Bearer token", forHTTPHeaderField: "Authorization")
let endpointFromRequest = urlRequest.toEndpoint()
```

### Making Requests with DefaultAPIService

`DefaultAPIService` is a singleton class that conforms to `APIService`. It provides a default implementation for making network requests.

```swift
let apiService = APIServices.default
let endpoint = MyEndpoint()

let cancellable = apiService.request(endpoint)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request finished")
        case .failure(let error):
            print("Request failed with error: \(error)")
        }
    }, receiveValue: { response, data in
        // Handle response and data
        print("Received response: \(response)")
        print("Received data: \(data)")
    })
```

### Creating Requests with URLRequestConvertible

You can create requests with any type that conforms to `URLRequestConvertible`, such as `String`, `URL`, or `URLRequest`.

```swift
let apiService = APIServices.default

// Using a String
let urlString = "https://api.example.com/v1/resource"

// Using a URL
let url = URL(string: "https://api.example.com/v1/resource")!

// Using a URLRequest
var urlRequest = URLRequest(url: url)
urlRequest.httpMethod = "GET"
urlRequest.setValue("Bearer token", forHTTPHeaderField: "Authorization")

// Making requests
let cancellableFromString = apiService.request(urlString)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request from string finished")
        case .failure(let error):
            print("Request from string failed with error: \(error)")
        }
    }, receiveValue: { response, data in
        // Handle response and data
        print("Received response from string: \(response)")
        print("Received data from string: \(data)")
    })

let cancellableFromURL = apiService.request(url)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request from URL finished")
        case .failure(let error):
            print("Request from URL failed with error: \(error)")
        }
    }, receiveValue: { response, data in
        // Handle response and data
        print("Received response from URL: \(response)")
        print("Received data from URL: \(data)")
    })

let cancellableFromRequest = apiService.request(urlRequest)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request from URLRequest finished")
        case .failure(let error):
            print("Request from URLRequest failed with error: \(error)")
        }
    }, receiveValue: { response, data in
        // Handle response and data
        print("Received response from URLRequest: \(response)")
        print("Received data from URLRequest: \(data)")
    })
```

```swift
        print("Received events response: \(response)")
        print("Received events data: \(data)")
    })
```

### Using `AnyPublisher` Extensions

The `AnyPublisher` extensions provide convenient methods for handling the data, decoding JSON, and more.

#### Decoding JSON

You can use the `data(type:decoder:)` method to decode the data into a specified type.

```swift
struct MyData: Decodable {
    let id: Int
    let name: String
}

let apiService = APIServices.default
let endpoint = BaseEndpoint(urlString: "https://api.example.com/v1/resource")

let cancellable = apiService.request(endpoint)
    .data(type: MyData.self)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request finished")
        case .failure(let error):
            print("Request failed with error: \(error)")
        }
    }, receiveValue: { myData in
        // Handle decoded data
        print("Received data: \(myData)")
    })
```

#### Emitting Raw Data

You can use the `data()` method to emit only the raw data.

```swift
let cancellable = apiService.request(endpoint)
    .data()
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request finished")
        case .failure(let error):
            print("Request failed with error: \(error)")
        }
    }, receiveValue: { data in
        // Handle raw data
        print("Received raw data: \(data)")
    })
```

#### Ignoring Data

You can use the `plain()` method to emit a `Void` value, effectively ignoring the data.

```swift
let cancellable = apiService.request(endpoint)
    .plain()
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request finished")
        case .failure(let error):
            print("Request failed with error: \(error)")
        }
    }, receiveValue: {
        // Handle completion
        print("Request completed successfully")
    })
```

#### Emitting JSON Data

You can use the `json()` method to emit JSON data.

```swift
let cancellable = apiService.request(endpoint)
    .json()
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request finished")
        case .failure(let error):
            print("Request failed with error: \(error)")
        }
    }, receiveValue: { jsonData in
        // Handle JSON data
        if let jsonData = jsonData {
            print("Received JSON data: \(jsonData)")
        } else {
            print("Failed to parse JSON data")
        }
    })
```

### Progress Tracking

For download and data tasks with progress tracking, you can use `DownloadWithProgress` and `DataWithProgress` protocols provided by `DefaultAPIService`.

```swift
let downloadService = APIServices.default
let downloadEndpoint = BaseEndpoint(urlString: "https://example.com/largefile.zip")

let downloadCancellable = downloadService.downloadWithProgress(downloadEndpoint)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Download finished")
        case .failure(let error):
            print("Download failed with error: \(error)")
        }
    }, receiveValue: { result in
        if let url = result.url {
            print("Downloaded file URL: \(url)")
        }
        if let progress = result.progress {
            print("Download progress: \(progress * 100)%")
        }
    })

let dataService = APIServices.default
let dataEndpoint = BaseEndpoint(urlString: "https://api.example.com/v1/resource")

let dataCancellable = dataService.requestDataWithProgress(dataEndpoint)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Data task finished")
        case .failure(let error):
            print("Data task failed with error: \(error)")
        }
    }, receiveValue: { result in
        if let data = result.data {
            print("Received data: \(data)")
        }
        if let progress = result.progress {
            print("Data task progress: \(progress * 100)%")
        }
    })
```

### Custom Logging

You can configure different logging levels by setting the `logger` property of `APIService`.

```swift
let apiService = APIServices.default
apiService.logger = APILoggers.verbose // Set to desired logger
```

#### Implementing Custom Loggers

You can create your own custom logger by conforming to the `APILogger` protocol. This allows you to define custom logging behavior for API requests and responses.

## License

`APIService` is available under the MIT license. See the [LICENSE](LICENSE) file for more information.
