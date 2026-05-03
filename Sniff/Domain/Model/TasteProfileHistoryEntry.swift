//
//  TasteProfileHistoryEntry.swift
//  Sniff
//
//  Created by OpenAI Codex on 2026.04.30.
//

import Foundation

struct TasteProfileHistoryEntry: Sendable {
    let id: String
    let title: String
    let families: [String]
    let scentVector: [String: Double]
    let collectionCount: Int
    let tastingCount: Int
    let stage: String
    let createdAt: Date?
}
