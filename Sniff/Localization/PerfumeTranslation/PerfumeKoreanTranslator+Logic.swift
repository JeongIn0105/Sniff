//
//  PerfumeKoreanTranslator+Logic.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension PerfumeKoreanTranslator {
    static func containsKorean(_ text: String) -> Bool {
        text.unicodeScalars.contains {
            (0xAC00...0xD7A3).contains($0.value) ||
            (0x1100...0x11FF).contains($0.value) ||
            (0x3130...0x318F).contains($0.value)
        }
    }

    static func korean(for accord: String) -> String {
        if containsKorean(accord) { return accord }
        if let korean = accordToKorean[accord] { return korean }
        return lowerAccordToKorean[accord.lowercased()] ?? accord
    }

    static func koreanAccords(for accords: [String]) -> [String] {
        accords.map { korean(for: $0) }
    }

    static func koreanBrand(for brand: String) -> String {
        let trimmed = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return brand }
        if containsKorean(trimmed) { return trimmed }
        if let korean = brandToKorean[trimmed] { return korean }
        if let korean = lowerBrandToKorean[trimmed.lowercased()] { return korean }
        return normalizedBrandToKorean[normalizeBrandKey(trimmed)] ?? trimmed
    }

    static func isDomesticRetailFocusedBrand(_ brand: String) -> Bool {
        domesticRetailPriority(for: brand) > 0
    }

    static func domesticRetailPriority(for brand: String) -> Int {
        let trimmed = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        if let priority = domesticRetailBrandPriority[trimmed] { return priority }
        return normalizedDomesticRetailBrandPriority[normalizeBrandKey(trimmed)] ?? 0
    }

    static func domesticRetailPriority(for perfume: Perfume) -> Int {
        ([perfume.brand] + perfume.brandAliases)
            .map { domesticRetailPriority(for: $0) }
            .max() ?? 0
    }

    static func sortedByDomesticRetailPriority(_ perfumes: [Perfume]) -> [Perfume] {
        perfumes.sorted { lhs, rhs in
            let lhsPriority = domesticRetailPriority(for: lhs)
            let rhsPriority = domesticRetailPriority(for: rhs)
            if lhsPriority != rhsPriority { return lhsPriority > rhsPriority }

            let lhsBrand = koreanBrand(for: lhs.brand)
            let rhsBrand = koreanBrand(for: rhs.brand)
            if lhsBrand != rhsBrand {
                return lhsBrand.localizedCaseInsensitiveCompare(rhsBrand) == .orderedAscending
            }

            let lhsName = koreanPerfumeName(for: lhs.name)
            let rhsName = koreanPerfumeName(for: rhs.name)
            return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
        }
    }

    static func koreanNote(for note: String) -> String {
        if containsKorean(note) { return note }
        if let korean = noteToKorean[note] { return korean }
        return lowerNoteToKorean[note.lowercased()] ?? note
    }

    static func koreanNotes(for notes: [String]) -> [String] {
        notes.map { koreanNote(for: $0) }
    }

    static func koreanConcentration(for concentration: String?) -> String {
        guard let concentration else { return "-" }
        let trimmed = concentration.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "-" }
        if containsKorean(trimmed) { return trimmed }

        let key = trimmed.lowercased()
        if let korean = concentrationToKorean[key] { return korean }

        return trimmed
            .replacingOccurrences(of: "eau de ", with: "오 드 ")
            .replacingOccurrences(of: "parfum", with: "퍼퓸")
            .replacingOccurrences(of: "toilette", with: "뚜왈렛")
            .replacingOccurrences(of: "cologne", with: "코롱")
            .capitalized
    }

    static func koreanPerfumeName(for perfumeName: String) -> String {
        let trimmed = perfumeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return perfumeName }
        if containsKorean(trimmed) { return trimmed }

        if let korean = perfumeNameToKorean[trimmed] {
            return korean
        }

        if let korean = normalizedPerfumeNameToKorean[normalizeBrandKey(trimmed)] {
            return korean
        }

        let domesticName = applyDomesticPerfumeNameReplacements(to: trimmed)
        if domesticName != trimmed {
            return domesticName
        }

        return PerfumeNameTranslationService.localTransliterate(trimmed)
    }

    static func koreanLongevity(for value: String?) -> String {
        guard let value else { return "-" }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "-" }
        if containsKorean(trimmed) { return trimmed }
        return longevityToKorean[trimmed.lowercased()] ?? trimmed
    }

    static func koreanSillage(for value: String?) -> String {
        guard let value else { return "-" }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "-" }
        if containsKorean(trimmed) { return trimmed }
        return sillageToKorean[trimmed.lowercased()] ?? trimmed
    }

    static func koreanSeason(for value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return value }
        if containsKorean(trimmed) { return trimmed }
        return seasonToKorean[trimmed.lowercased()] ?? trimmed
    }

    static func toEnglishQuery(_ query: String) -> String? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let english = koreanToAccord[trimmed] { return english }
        if let english = koreanToBrand[trimmed] { return english }

        let words = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var translatedWords: [String] = []
        var anyTranslated = false
        var i = 0

        while i < words.count {
            var matched = false
            for len in stride(from: min(3, words.count - i), through: 1, by: -1) {
                let phrase = words[i..<(i + len)].joined(separator: " ")
                if let eng = koreanToBrand[phrase] {
                    translatedWords.append(eng)
                    i += len
                    anyTranslated = true
                    matched = true
                    break
                }
            }
            if !matched {
                let word = words[i]
                if let eng = koreanWordToEnglish[word] {
                    translatedWords.append(eng)
                    anyTranslated = true
                } else if let prefixMatch = koreanWordToEnglish.first(where: { $0.key.hasPrefix(word) && $0.key != word }) {
                    translatedWords.append(prefixMatch.value)
                    anyTranslated = true
                } else {
                    translatedWords.append(word)
                }
                i += 1
            }
        }

        if anyTranslated { return translatedWords.joined(separator: " ") }

        for (korean, english) in koreanToBrand {
            if trimmed.localizedCaseInsensitiveContains(korean) {
                let replaced = trimmed.replacingOccurrences(of: korean, with: english, options: .caseInsensitive)
                if replaced != trimmed { return replaced }
            }
        }

        return nil
    }
}
