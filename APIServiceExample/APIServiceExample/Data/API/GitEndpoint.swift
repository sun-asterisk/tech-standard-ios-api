//
//  GitEndpoint.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 15/05/2023.
//

import Foundation
import APIService

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

