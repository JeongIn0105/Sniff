//
//  AppSecrets.swift
//  Sniff
//
//  Created by Codex on 2026.04.15.
//

import Foundation

enum AppSecretsError: LocalizedError {
    case missingValue(String)

    var errorDescription: String? {
        switch self {
        case .missingValue(let key):
            return "\(key) 설정값을 찾을 수 없어요"
        }
    }
}

enum AppSecrets {
    static func geminiAPIKey() throws -> String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
            !value.isEmpty
        else {
            throw AppSecretsError.missingValue("GEMINI_API_KEY")
        }

        return value
    }

    static func fragellaAPIKey() throws -> String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "FRAGELLA_API_KEY") as? String,
            !value.isEmpty
        else {
            throw AppSecretsError.missingValue("FRAGELLA_API_KEY")
        }

        return value
    }
}
