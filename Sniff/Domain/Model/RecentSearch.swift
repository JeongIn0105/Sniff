//
//  RecentSearch.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

struct RecentSearch: Equatable, Codable {
    let query: String
    let date: Date

    init(query: String) {
        self.query = query
        self.date = Date()
    }
}
