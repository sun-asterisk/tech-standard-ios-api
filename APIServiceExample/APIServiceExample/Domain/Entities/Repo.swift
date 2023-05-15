//
//  Repo.swift
//  APIServiceExample
//
//  Created by Tuan Truong on 15/05/2023.
//

import Foundation
import Then

struct Repo {
    struct Owner: Codable, Equatable {
        var id = 0
        var login = ""
        var avatarUrl = ""
        
        enum CodingKeys: String, CodingKey {
            case id
            case login
            case avatarUrl = "avatar_url"
        }
    }
    
    var id = 0
    var name = ""
    var fullName = ""
    var url = ""
    var eventUrl = ""
    var stars = 0
    var forks = 0
    var owner: Owner?
}

extension Repo: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case url
        case eventUrl = "events_url"
        case stars = "stargazers_count"
        case forks
        case owner
    }
}

extension Repo: Then, Identifiable, Equatable { }
