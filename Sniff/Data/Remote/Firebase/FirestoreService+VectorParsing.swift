//
//  FirestoreService+VectorParsing.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.16.
//


import Foundation
import FirebaseFirestore

extension FirestoreService {

        // MARK: - CollectedPerfume 파싱 (V2)

    static func makeCollectedPerfumeV2(from document: QueryDocumentSnapshot) -> CollectedPerfume? {
        let data = document.data()

        guard
            let name = data["name"] as? String,
            let brand = data["brand"] as? String
        else { return nil }

        let timestamp = data["addedAt"] as? Timestamp

        let rawMainAccords = data["mainAccords"] as? [String] ?? []
        let legacyAccords = [data["scentFamily"] as? String, data["scentFamily2"] as? String]
            .compactMap { $0 }
        let mainAccords = ScentFamilyNormalizer.canonicalNames(
            for: rawMainAccords.isEmpty ? legacyAccords : rawMainAccords
        )

        let rawStrengths = data["accordStrengths"] as? [String: String] ?? [:]
        let accordStrengths = parseAccordStrengths(from: rawStrengths)

        let seasonRanking: [SeasonRankingEntry] = (data["seasonRanking"] as? [[String: Any]] ?? [])
            .compactMap { entry in
                guard let name = entry["name"] as? String, let score = entry["score"] as? Double else { return nil }
                return SeasonRankingEntry(name: name, score: score)
            }

        return CollectedPerfume(
            id: document.documentID,
            name: name,
            brand: brand,
            imageUrl: data["imageUrl"] as? String ?? data["imageURL"] as? String,
            mainAccords: mainAccords,
            accordStrengths: accordStrengths,
            memo: data["memo"] as? String,
            createdAt: timestamp?.dateValue(),
            topNotes: data["topNotes"] as? [String],
            middleNotes: data["middleNotes"] as? [String],
            baseNotes: data["baseNotes"] as? [String],
            generalNotes: data["generalNotes"] as? [String],
            seasonRanking: seasonRanking,
            concentration: data["concentration"] as? String,
            longevity: data["longevity"] as? String,
            sillage: data["sillage"] as? String
        )
    }

        // MARK: - TastingRecord 파싱 (V2)

    static func makeTastingRecordV2(from document: QueryDocumentSnapshot) -> TastingRecord? {
        let data = document.data()

        guard
            let perfumeName = data["perfumeName"] as? String,
            let brandName = data["brandName"] as? String,
            let rating = data["rating"] as? Int,
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        else { return nil }

        let rawStrengths = data["accordStrengths"] as? [String: String] ?? [:]
        let accordStrengths = parseAccordStrengths(from: rawStrengths)

        return TastingRecord(
            id: document.documentID,
            perfumeName: perfumeName,
            brandName: brandName,
            mainAccords: data["mainAccords"] as? [String] ?? [],
            accordStrengths: accordStrengths,
            rating: rating,
            moodTags: data["moodTags"] as? [String] ?? [],
            memo: data["memo"] as? String,
            revisitDesire: (data["revisitDesire"] as? String) ?? (data["wantToRevisit"] as? String),
            updatedAt: updatedAt
        )
    }

        // MARK: - Private

    private static func parseAccordStrengths(
        from raw: [String: String]
    ) -> [String: AccordStrength] {
        raw.reduce(into: [String: AccordStrength]()) { result, pair in
            guard
                let canonical = ScentFamilyNormalizer.canonicalName(for: pair.key),
                let strength = AccordStrength(rawDescription: pair.value)
            else { return }
            result[canonical] = strength
        }
    }
}
