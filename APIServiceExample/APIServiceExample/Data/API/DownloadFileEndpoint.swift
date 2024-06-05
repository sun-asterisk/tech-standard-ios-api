//
//  DownloadFileEndpoint.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 4/6/24.
//

import Foundation
import APIService

enum DownloadFileEndpoint {
    case image(url: String)
}

extension DownloadFileEndpoint: Endpoint {
    var urlString: String? {
        switch self {
        case .image(let url):
            return url
        }
    }
}
