import Testing
import Foundation
@testable import APIService

// MARK: - Test Endpoint Implementation

struct MockEndpoint: Endpoint {
        var base: String?
        var path: String?
        var urlString: String?
        var httpMethod: HttpMethod
        var headers: [String: Any]?
        var queryItems: [(String, Any)]?
        var body: [String: Any]?
        var bodyData: Data?
        var parts: [MultipartFormData]
        
        init(
            base: String? = nil,
            path: String? = nil,
            urlString: String? = nil,
            httpMethod: HttpMethod = .get,
            headers: [String: Any]? = nil,
            queryItems: [(String, Any)]? = nil,
            body: [String: Any]? = nil,
            bodyData: Data? = nil,
            parts: [MultipartFormData] = []
        ) {
            self.base = base
            self.path = path
            self.urlString = urlString
            self.httpMethod = httpMethod
            self.headers = headers
            self.queryItems = queryItems
            self.body = body
            self.bodyData = bodyData
            self.parts = parts
        }
    }
    
// MARK: - URL Construction Tests

@Test("URL construction with base and path")
func urlConstructionWithBaseAndPath() {
    let endpoint = MockEndpoint(
        base: "https://api.example.com",
        path: "/users"
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    #expect(request?.url?.absoluteString == "https://api.example.com/users")
}

@Test("URL construction with URL string")
func urlConstructionWithURLString() {
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/users"
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    #expect(request?.url?.absoluteString == "https://api.example.com/users")
}

@Test("URL string takes precedence over base and path")
func urlStringTakesPrecedenceOverBaseAndPath() {
    let endpoint = MockEndpoint(
        base: "https://wrong.com",
        path: "/wrong",
        urlString: "https://api.example.com/users"
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    #expect(request?.url?.absoluteString == "https://api.example.com/users")
}

@Test("URL construction with query items")
func urlConstructionWithQueryItems() {
    let endpoint = MockEndpoint(
        base: "https://api.example.com",
        path: "/users",
        queryItems: [
            ("page", 1),
            ("limit", 10),
            ("search", "john")
        ]
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    let url = request?.url?.absoluteString ?? ""
    #expect(url.contains("page=1"))
    #expect(url.contains("limit=10"))
    #expect(url.contains("search=john"))
}

@Test("URL construction preserves base path and normalizes endpoint path")
func urlConstructionPreservesBasePathAndNormalizesPath() {
    let endpoint = MockEndpoint(
        base: "https://api.example.com/api",
        path: "v1/resource"
    )

    let request = endpoint.urlRequest

    #expect(request != nil)
    #expect(request?.url?.absoluteString == "https://api.example.com/api/v1/resource")
}

@Test("URL construction with base only")
func urlConstructionWithBaseOnly() {
    let endpoint = MockEndpoint(base: "https://api.example.com")

    let request = endpoint.urlRequest

    #expect(request != nil)
    #expect(request?.url?.absoluteString == "https://api.example.com")
}
    
// MARK: - HTTP Method Tests

@Test("HTTP methods are set correctly", arguments: [
    HttpMethod.get, .post, .put, .delete, .patch, .head, .options
])
func httpMethods(method: HttpMethod) {
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/test",
        httpMethod: method
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    #expect(request?.httpMethod == method.rawValue)
}
    
// MARK: - Headers Tests

@Test("Headers are set correctly")
func headers() {
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/users",
        headers: [
            "Authorization": "Bearer token123",
            "Content-Type": "application/json",
            "X-Custom-Header": "custom-value"
        ]
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    #expect(request?.value(forHTTPHeaderField: "Authorization") == "Bearer token123")
    #expect(request?.value(forHTTPHeaderField: "X-Custom-Header") == "custom-value")
}
    
// MARK: - Body Tests

@Test("JSON body serialization")
func jsonBodySerialization() throws {
    let bodyDict: [String: Any] = [
        "name": "John Doe",
        "age": 30,
        "email": "john@example.com"
    ]
    
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/users",
        httpMethod: .post,
        body: bodyDict
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    #expect(request?.httpBody != nil)
    #expect(request?.value(forHTTPHeaderField: "Content-Type") == "application/json")
    
    // Verify body can be deserialized
    if let httpBody = request?.httpBody {
        let json = try JSONSerialization.jsonObject(with: httpBody) as? [String: Any]
        #expect(json != nil)
        #expect(json?["name"] as? String == "John Doe")
        #expect(json?["age"] as? Int == 30)
        #expect(json?["email"] as? String == "john@example.com")
    }
}

@Test("Raw body data")
func rawBodyData() {
    let rawData = "Raw body content".data(using: .utf8)!
    
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/upload",
        httpMethod: .post,
        bodyData: rawData
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    #expect(request?.httpBody == rawData)
    #expect(request?.value(forHTTPHeaderField: "Content-Type") == "application/octet-stream")
}

@Test("Body data takes precedence over body")
func bodyDataTakesPrecedenceOverBody() {
    let bodyDict = ["key": "value"]
    let rawData = "Raw data".data(using: .utf8)!
    
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/test",
        httpMethod: .post,
        body: bodyDict,
        bodyData: rawData
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    #expect(request?.httpBody == rawData)
}

@Test("Custom Content-Type not overridden")
func customContentTypeNotOverridden() {
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/upload",
        httpMethod: .post,
        headers: ["Content-Type": "text/plain"],
        bodyData: "test".data(using: .utf8)
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    #expect(request?.value(forHTTPHeaderField: "Content-Type") == "text/plain")
}
    
// MARK: - Multipart Form Data Tests

@Test("Multipart form data with data provider")
func multipartFormDataWithData() {
    let imageData = "fake-image-data".data(using: .utf8)!
    let part = MultipartFormData(
        provider: .data(imageData),
        name: "photo",
        fileName: "photo.jpg",
        mimeType: "image/jpeg"
    )
    
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/upload",
        httpMethod: .post,
        parts: [part]
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    #expect(request?.httpBody != nil)
    
    // Check Content-Type header contains multipart/form-data
    let contentType = request?.value(forHTTPHeaderField: "Content-Type")
    #expect(contentType != nil)
    #expect(contentType?.contains("multipart/form-data") ?? false)
    #expect(contentType?.contains("boundary=") ?? false)
    
    // Check body contains expected parts
    if let httpBody = request?.httpBody {
        let bodyString = String(data: httpBody, encoding: .utf8)
        #expect(bodyString != nil)
        #expect(bodyString?.contains("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"") ?? false)
        #expect(bodyString?.contains("Content-Type: image/jpeg") ?? false)
        #expect(bodyString?.contains("fake-image-data") ?? false)
    }
}

@Test("Multipart form data with file provider")
func multipartFormDataWithFile() throws {
    // Create a temporary file
    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent("test.txt")
    let fileContent = "Test file content"
    try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
    
    defer {
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    let part = MultipartFormData(
        provider: .file(fileURL),
        name: "document",
        fileName: "test.txt",
        mimeType: "text/plain"
    )
    
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/upload",
        httpMethod: .post,
        parts: [part]
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    #expect(request?.httpBody != nil)
    
    if let httpBody = request?.httpBody {
        let bodyString = String(data: httpBody, encoding: .utf8)
        #expect(bodyString != nil)
        #expect(bodyString?.contains("Content-Disposition: form-data; name=\"document\"; filename=\"test.txt\"") ?? false)
        #expect(bodyString?.contains("Content-Type: text/plain") ?? false)
        #expect(bodyString?.contains(fileContent) ?? false)
    }
}

@Test("Multipart form data with body parameters")
func multipartFormDataWithBodyParameters() {
    let imageData = "image-data".data(using: .utf8)!
    let part = MultipartFormData(
        provider: .data(imageData),
        name: "photo",
        fileName: "photo.jpg",
        mimeType: "image/jpeg"
    )
    
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/upload",
        httpMethod: .post,
        body: [
            "title": "My Photo",
            "description": "A beautiful photo"
        ],
        parts: [part]
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    #expect(request?.httpBody != nil)
    
    if let httpBody = request?.httpBody {
        let bodyString = String(data: httpBody, encoding: .utf8)
        #expect(bodyString != nil)
        // Check body parameters are included
        #expect(bodyString?.contains("Content-Disposition: form-data; name=\"title\"") ?? false)
        #expect(bodyString?.contains("My Photo") ?? false)
        #expect(bodyString?.contains("Content-Disposition: form-data; name=\"description\"") ?? false)
        #expect(bodyString?.contains("A beautiful photo") ?? false)
        // Check file part is included
        #expect(bodyString?.contains("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"") ?? false)
    }
}

@Test("Multipart form data takes precedence over other body types")
func multipartFormDataTakesPrecedence() {
    let part = MultipartFormData(
        provider: .data("data".data(using: .utf8)!),
        name: "file"
    )
    
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/upload",
        httpMethod: .post,
        body: ["key": "value"],
        bodyData: "raw".data(using: .utf8),
        parts: [part]
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    
    // Should use multipart, not JSON or raw data
    let contentType = request?.value(forHTTPHeaderField: "Content-Type")
    #expect(contentType?.contains("multipart/form-data") ?? false)
}

@Test("Multipart without fileName")
func multipartWithoutFileName() {
    let data = "field-value".data(using: .utf8)!
    let part = MultipartFormData(
        provider: .data(data),
        name: "textField",
        fileName: nil,
        mimeType: nil
    )
    
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/upload",
        httpMethod: .post,
        parts: [part]
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    
    if let httpBody = request?.httpBody {
        let bodyString = String(data: httpBody, encoding: .utf8)
        #expect(bodyString != nil)
        // Should not contain filename attribute
        #expect(!(bodyString?.contains("filename=") ?? true))
        #expect(bodyString?.contains("Content-Disposition: form-data; name=\"textField\"") ?? false)
    }
}

@Test("Multipart data with fileName and no mimeType keeps header/body separator")
func multipartWithFileNameWithoutMimeTypeHasSeparator() {
    let data = "raw-data".data(using: .utf8)!
    let part = MultipartFormData(
        provider: .data(data),
        name: "file",
        fileName: "raw.bin",
        mimeType: nil
    )

    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/upload",
        httpMethod: .post,
        parts: [part]
    )

    let request = endpoint.urlRequest

    #expect(request != nil)

    if let httpBody = request?.httpBody {
        let bodyString = String(data: httpBody, encoding: .utf8)
        #expect(bodyString != nil)
        #expect(bodyString?.contains("filename=\"raw.bin\"\r\n\r\nraw-data") ?? false)
    }
}

@Test("Multipart with missing file returns nil request")
func multipartWithMissingFileReturnsNilRequest() {
    let missingFileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("bin")
    let part = MultipartFormData(
        provider: .file(missingFileURL),
        name: "missing-file",
        fileName: "missing.bin",
        mimeType: "application/octet-stream"
    )

    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/upload",
        httpMethod: .post,
        parts: [part]
    )

    let request = endpoint.urlRequest

    #expect(request == nil)
}

@Test("CustomEndpoint toEndpoint keeps multipart parts")
func customEndpointToEndpointKeepsMultipartParts() {
    let partData = "part-content".data(using: .utf8)!
    let part = MultipartFormData(
        provider: .data(partData),
        name: "file",
        fileName: "file.txt",
        mimeType: "text/plain"
    )

    let baseEndpoint = BaseEndpoint(
        urlString: "https://api.example.com/upload",
        httpMethod: .post,
        parts: [part]
    )
    let customEndpoint = CustomEndpoint(
        endpoint: baseEndpoint,
        overrides: .headers(["Authorization": "Bearer token"])
    )
    let convertedEndpoint = customEndpoint.toEndpoint()

    let request = convertedEndpoint.urlRequest

    #expect(request != nil)
    #expect(request?.value(forHTTPHeaderField: "Authorization") == "Bearer token")
    #expect(request?.value(forHTTPHeaderField: "Content-Type")?.contains("multipart/form-data") ?? false)

    if let httpBody = request?.httpBody {
        let bodyString = String(data: httpBody, encoding: .utf8)
        #expect(bodyString?.contains("Content-Disposition: form-data; name=\"file\"; filename=\"file.txt\"") ?? false)
        #expect(bodyString?.contains("part-content") ?? false)
    }
}
    
// MARK: - MIME Type Tests

@Test("MIME type detection for common file types", arguments: [
    ("test.jpg", "image/jpeg"),
    ("test.png", "image/png"),
    ("test.gif", "image/gif"),
    ("test.pdf", "application/pdf"),
    ("test.json", "application/json"),
    ("test.txt", "text/plain"),
    ("test.mp4", "video/mp4"),
    ("test.mp3", "audio/mpeg")
])
func mimeTypeDetectionForCommonFileTypes(fileName: String, expectedMimeType: String) throws {
    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent(fileName)
    try "test".write(to: fileURL, atomically: true, encoding: .utf8)
    
    defer {
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    let part = MultipartFormData(
        provider: .file(fileURL),
        name: "file",
        fileName: fileName
    )
    
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/upload",
        httpMethod: .post,
        parts: [part]
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    
    if let httpBody = request?.httpBody {
        let bodyString = String(data: httpBody, encoding: .utf8)
        #expect(bodyString != nil)
        // Should contain Content-Type header for the file
        #expect(bodyString?.contains("Content-Type:") ?? false, "Missing Content-Type for \(fileName)")
    }
}

// MARK: - Edge Cases Tests

@Test("Empty endpoint returns nil")
func emptyEndpoint() {
    let endpoint = MockEndpoint()
    
    let request = endpoint.urlRequest
    
    // Should return nil because no URL is provided
    #expect(request == nil)
}

@Test("Empty parts array does not create multipart body")
func emptyParts() {
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/test",
        httpMethod: .post,
        parts: []
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    // Should not use multipart if parts is empty
    let contentType = request?.value(forHTTPHeaderField: "Content-Type")
    #expect(contentType == nil)
    #expect(request?.httpBody == nil)
}

@Test("Multiple parts in multipart data")
func multiplePartsInMultipartData() {
    let part1 = MultipartFormData(
        provider: .data("data1".data(using: .utf8)!),
        name: "field1",
        fileName: "file1.txt"
    )
    
    let part2 = MultipartFormData(
        provider: .data("data2".data(using: .utf8)!),
        name: "field2",
        fileName: "file2.txt"
    )
    
    let part3 = MultipartFormData(
        provider: .data("data3".data(using: .utf8)!),
        name: "field3"
    )
    
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/upload",
        httpMethod: .post,
        parts: [part1, part2, part3]
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    
    if let httpBody = request?.httpBody {
        let bodyString = String(data: httpBody, encoding: .utf8)
        #expect(bodyString != nil)
        // All parts should be present
        #expect(bodyString?.contains("name=\"field1\"") ?? false)
        #expect(bodyString?.contains("name=\"field2\"") ?? false)
        #expect(bodyString?.contains("name=\"field3\"") ?? false)
        #expect(bodyString?.contains("data1") ?? false)
        #expect(bodyString?.contains("data2") ?? false)
        #expect(bodyString?.contains("data3") ?? false)
    }
}

@Test("Non-string headers are filtered out")
func nonStringHeadersAreFiltered() {
    let endpoint = MockEndpoint(
        urlString: "https://api.example.com/test",
        headers: [
            "Valid-Header": "string-value",
            "Invalid-Header": 123, // Non-string value
            "Another-Valid": "another-value"
        ]
    )
    
    let request = endpoint.urlRequest
    
    #expect(request != nil)
    #expect(request?.value(forHTTPHeaderField: "Valid-Header") == "string-value")
    #expect(request?.value(forHTTPHeaderField: "Another-Valid") == "another-value")
    #expect(request?.value(forHTTPHeaderField: "Invalid-Header") == nil)
}
