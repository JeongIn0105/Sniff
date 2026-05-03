//
//  SubFamilyClassifierFactory.swift
//  Sniff
//
//  Created by OpenAI Codex on 2026.04.29.
//

import Foundation

enum SubFamilyClassifierFactory {
    static func make() throws -> SubFamilyClassifier {
        let cache = FirestoreAccordCacheRepository()
        let geminiClassifier = GeminiAccordClassifier(
            geminiAPIKey: try AppSecrets.geminiAPIKey(),
            cache: cache
        )
        return SubFamilyClassifier(geminiClassifier: geminiClassifier)
    }
}
