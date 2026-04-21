//
//  PerfumePresentationSupport.swift
//  Sniff
//
//  Created by Codex on 2026.04.20.
//

import Foundation

enum PerfumePresentationSupport {
    static func previewAccords(mainAccords: [String], fallback: [String]) -> [String] {
        let source = mainAccords.isEmpty ? fallback : mainAccords
        return Array(source.prefix(2))
    }

    static func recordKey(perfumeName: String, brandName: String) -> String {
        "\(brandName.lowercased())|\(perfumeName.lowercased())"
    }
}
