//
//  PerfumePresentationSupport.swift
//  Sniff
//
//  Created by Codex on 2026.04.20.
//

import Foundation

enum PerfumePresentationSupport {
    static func displayBrand(_ brand: String) -> String {
        PerfumeKoreanTranslator.koreanBrand(for: brand)
    }

    static func displayPerfumeName(_ perfumeName: String) -> String {
        PerfumeKoreanTranslator.koreanPerfumeName(for: perfumeName)
    }

    static func displayAccord(_ accord: String) -> String {
        PerfumeKoreanTranslator.korean(for: accord)
    }

    static func displayAccords(_ accords: [String]) -> [String] {
        PerfumeKoreanTranslator.koreanAccords(for: accords)
    }

    static func displayNotes(_ notes: [String]) -> [String] {
        PerfumeKoreanTranslator.koreanNotes(for: notes)
    }

    static func displayConcentration(_ concentration: String?) -> String {
        PerfumeKoreanTranslator.koreanConcentration(for: concentration)
    }

    static func displayLongevity(_ longevity: String?) -> String {
        PerfumeKoreanTranslator.koreanLongevity(for: longevity)
    }

    static func displaySillage(_ sillage: String?) -> String {
        PerfumeKoreanTranslator.koreanSillage(for: sillage)
    }

    static func displaySeasons(_ seasons: [String]) -> [String] {
        seasons.map { PerfumeKoreanTranslator.koreanSeason(for: $0) }
    }

    static func previewAccords(mainAccords: [String], fallback: [String]) -> [String] {
        let source = mainAccords.isEmpty ? fallback : mainAccords
        return displayAccords(Array(source.prefix(2)))
    }

    static func recordKey(perfumeName: String, brandName: String) -> String {
        "\(brandName.lowercased())|\(perfumeName.lowercased())"
    }
}
