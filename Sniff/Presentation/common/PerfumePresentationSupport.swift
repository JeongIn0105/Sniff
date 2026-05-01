//
//  PerfumePresentationSupport.swift
//  Sniff
//
//  Created by Codex on 2026.04.20.
//

import Foundation

enum PerfumePresentationSupport {
    nonisolated static func displayBrand(_ brand: String) -> String {
        PerfumeKoreanTranslator.koreanBrand(for: brand)
    }

    nonisolated static func displayPerfumeName(_ perfumeName: String) -> String {
        PerfumeKoreanTranslator.koreanPerfumeName(for: perfumeName)
    }

    nonisolated static func displayAccord(_ accord: String) -> String {
        PerfumeKoreanTranslator.korean(for: accord)
    }

    nonisolated static func displayAccords(_ accords: [String]) -> [String] {
        PerfumeKoreanTranslator.koreanAccords(for: accords)
    }

    nonisolated static func displayFamily(_ family: String) -> String {
        PerfumeKoreanTranslator.koreanFamily(for: family)
    }

    nonisolated static func displayFamilies(_ families: [String]) -> [String] {
        PerfumeKoreanTranslator.koreanFamilies(for: families)
    }

    nonisolated static func displayNotes(_ notes: [String]) -> [String] {
        PerfumeKoreanTranslator.koreanNotes(for: notes)
    }

    nonisolated static func displayConcentration(_ concentration: String?) -> String {
        PerfumeKoreanTranslator.koreanConcentration(for: concentration)
    }

    nonisolated static func displayLongevity(_ longevity: String?) -> String {
        PerfumeKoreanTranslator.koreanLongevity(for: longevity)
    }

    nonisolated static func displaySillage(_ sillage: String?) -> String {
        PerfumeKoreanTranslator.koreanSillage(for: sillage)
    }

    nonisolated static func displaySeasons(_ seasons: [String]) -> [String] {
        seasons.map { PerfumeKoreanTranslator.koreanSeason(for: $0) }
    }

    nonisolated static func previewAccords(mainAccords: [String], fallback: [String]) -> [String] {
        let source = mainAccords.isEmpty ? fallback : mainAccords
        return displayAccords(Array(source.prefix(2)))
    }

    nonisolated static func recordKey(perfumeName: String, brandName: String) -> String {
        primaryRecordKey(
            perfumeName: displayPerfumeName(perfumeName),
            brandName: displayBrand(brandName)
        )
    }

    nonisolated static func recordMatchingKeys(perfumeName: String, brandName: String) -> Set<String> {
        [
            primaryRecordKey(perfumeName: perfumeName, brandName: brandName),
            recordKey(perfumeName: perfumeName, brandName: brandName)
        ]
    }

    private nonisolated static func primaryRecordKey(perfumeName: String, brandName: String) -> String {
        let normalizedBrand = brandName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()

        let normalizedPerfume = perfumeName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()

        return "\(normalizedBrand)|\(normalizedPerfume)"
    }
}
