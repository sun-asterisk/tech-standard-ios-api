# APIService

A Swift protocol and extensions for making network requests with Combine. Includes support for data tasks, download tasks, and progress updates.

## Installation

### Swift Package Manager (SPM)

To integrate `APIService` into your project using Swift Package Manager, add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/sun-asterisk/tech-standard-ios-api", from: "0.2.0")
]
```

Then, add `APIService` to your target dependencies:

```swift
.target(
    name: "YourTargetName",
    dependencies: ["APIService"]
)
```

## Usage

### Defining an Endpoint

First, define your endpoints by conforming to the `Endpoint` protocol. For example, using GitHub API endpoints:

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

### Implementing APIService

You can create a class or struct that conforms to `APIService` and optionally to `DownloadWithProgress` or `DataWithProgress` if you need progress updates. Alternatively, you can use the provided `DefaultAPIService` class which already conforms to these protocols.

#### Using DefaultAPIService

```swift
import Combine

let apiService = DefaultAPIService.shared
```

#### Custom APIService Implementation

```swift
import Combine

class GitHubAPI: APIService {
    var session: URLSession {
        return URLSession.shared
    }
}

let api = GitHubAPI()
```

### Making Requests

Use the `request` method to make network requests and decode the response data:

```swift
import Combine

struct Repo: Decodable {
    let id: Int
    let name: String
    let fullName: String
}

let gitHubAPI = DefaultAPIService.shared
let endpoint = GitEndpoint.repos(page: 1, perPage: 10)

let cancellable = gitHubAPI.request(endpoint, decodingType: [Repo].self)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Request completed successfully.")
        case .failure(let error):
            print("Request failed with error: \(error)")
        }
    }, receiveValue: { repos in
        print("Received repos: \(repos)")
    })
```

### Downloading with Progress

To perform a download task with progress updates, use the `downloadWithProgress` method with `DefaultAPIService` or your custom implementation:

```swift
let downloadAPI = DefaultAPIService.shared
let downloadEndpoint = GitEndpoint.repos(page: 1, perPage: 10)

let downloadCancellable = downloadAPI.downloadWithProgress(downloadEndpoint)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Download completed successfully.")
        case .failure(let error):
            print("Download failed with error: \(error)")
        }
    }, receiveValue: { url, progress in
        if let url = url {
            print("Downloaded file URL: \(url)")
        }
        if let progress = progress {
            print("Download progress: \(progress * 100)%")
        }
    })
```

## License

`APIService` is available under the MIT license. See the [LICENSE](LICENSE) file for more information.

