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
        guard let value = resolvedInfoValue(for: "GEMINI_API_KEY") else {
            throw AppSecretsError.missingValue("GEMINI_API_KEY")
        }

        return value
    }

    static func fragellaAPIKey() throws -> String {
        guard let value = resolvedInfoValue(for: "FRAGELLA_API_KEY") else {
            throw AppSecretsError.missingValue("FRAGELLA_API_KEY")
        }

        return value
    }

    private static func resolvedInfoValue(for key: String) -> String? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String
        else {
            return nil
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !trimmedValue.isEmpty,
            !trimmedValue.hasPrefix("$("),
            !trimmedValue.lowercased().contains("your_")
        else {
            return nil
        }

        return trimmedValue
    }
}
