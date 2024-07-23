import Foundation

public struct BaseEndpoint: Endpoint {
    public var base: String?
    public var path: String?
    public var urlString: String?
    public var httpMethod = HttpMethod.get
    public var headers: [String: Any]?
    public var queryItems: [String: Any]?
    public var body: [String: Any]?
    
    public init(base: String? = nil, 
         path: String? = nil,
         urlString: String? = nil,
         httpMethod: HttpMethod = HttpMethod.get,
         headers: [String : Any]? = nil,
         queryItems: [String : Any]? = nil,
         body: [String : Any]? = nil) {
        self.base = base
        self.path = path
        self.urlString = urlString
        self.httpMethod = httpMethod
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
    }
}
