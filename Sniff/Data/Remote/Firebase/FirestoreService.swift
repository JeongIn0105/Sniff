//
//  FirestoreService.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum FirestoreServiceError: LocalizedError {
    case missingAuthenticatedUser
    case invalidTasteAnalysisData

    var errorDescription: String? {
        switch self {
        case .missingAuthenticatedUser:
            return "로그인된 사용자 정보를 찾을 수 없어요"
        case .invalidTasteAnalysisData:
            return "저장된 취향 분석 데이터를 읽을 수 없어요"
        }
    }
}

final class FirestoreService {

    static let shared = FirestoreService()

    private let database = Firestore.firestore()

    private init() {}

    func isNicknameAvailable(_ nickname: String) async throws -> Bool {
        let normalizedNickname = normalizedNickname(nickname)
        guard !normalizedNickname.isEmpty else { return false }

        let currentUserID = try authenticatedUserID()
        let snapshot = try await database.collection("users")
            .whereField("nicknameLowercased", isEqualTo: normalizedNickname)
            .getDocuments()

        return snapshot.documents.allSatisfy { $0.documentID == currentUserID }
    }

    func saveUserProfile(
        nickname: String,
        tasteAnalysis: TasteAnalysisResult
    ) async throws {
        let now = FieldValue.serverTimestamp()
        let ref = try userDocumentRef()

        let data: [String: Any] = [
            "nickname": nickname,
            "nicknameLowercased": normalizedNickname(nickname),
            "tasteAnalysis": Self.tasteAnalysisDictionary(from: tasteAnalysis),
            "updatedAt": now,
            "createdAt": now
        ]

        try await ref.setData(data, merge: true)
    }

    func fetchTasteAnalysis() async throws -> TasteAnalysisResult {
        let snapshot = try await userDocumentRef().getDocument()
        let data = snapshot.data() ?? [:]

        if let nested = data["tasteAnalysis"] as? [String: Any] {
            return try Self.decodeTasteAnalysis(from: nested)
        }

        if let nested = data["taste_analysis"] as? [String: Any] {
            return try Self.decodeTasteAnalysis(from: nested)
        }

        if Self.looksLikeTasteAnalysisPayload(data) {
            return try Self.decodeTasteAnalysis(from: data)
        }

        throw FirestoreServiceError.invalidTasteAnalysisData
    }

    func fetchCollection() async throws -> [CollectedPerfume] {
        let snapshot = try await userDocumentRef()
            .collection("collection")
            .getDocuments()

        return snapshot.documents
            .compactMap(Self.makeCollectedPerfumeV2)
            .sorted { lhs, rhs in
                (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
            }
    }

    func fetchTastingRecords() async throws -> [TastingRecord] {
        let snapshot = try await userDocumentRef()
            .collection("tastingRecords")
            .getDocuments()

        return snapshot.documents
            .compactMap(Self.makeTastingRecordV2)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func saveCollectedPerfume(
        _ perfume: FragellaPerfume,
        memo: String? = nil
    ) async throws {
        let now = FieldValue.serverTimestamp()
        let ref = try userDocumentRef()
            .collection("collection")
            .document(perfume.id)

        var data: [String: Any] = [
            "name": perfume.name,
            "brand": perfume.brand,
            "imageUrl": perfume.imageUrl as Any,
            "mainAccords": perfume.mainAccords,
            "accordStrengths": Self.accordStrengthsForStorage(from: perfume),
            "concentration": perfume.concentration as Any,
            "gender": perfume.gender as Any,
            "addedAt": now,
            "updatedAt": now
        ]

        if let memo, !memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["memo"] = memo
        }

        try await ref.setData(data, merge: true)
    }

    func saveTastingRecord(
        id: String? = nil,
        fragellaPerfume: FragellaPerfume,
        rating: Int,
        moodTags: [String],
        memo: String?,
        wantToRevisit: String? = nil
    ) async throws {
        let now = FieldValue.serverTimestamp()
        let ref = try userDocumentRef()
            .collection("tastingRecords")
            .document(id ?? UUID().uuidString)

        var data: [String: Any] = [
            "perfumeName": fragellaPerfume.name,
            "brandName": fragellaPerfume.brand,
            "imageUrl": fragellaPerfume.imageUrl as Any,
            "mainAccords": fragellaPerfume.mainAccords,
            "accordStrengths": Self.accordStrengthsForStorage(from: fragellaPerfume),
            "rating": rating,
            "moodTags": moodTags,
            "updatedAt": now
        ]

        if let memo, !memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["memo"] = memo
        }

        if let wantToRevisit, !wantToRevisit.isEmpty {
            data["wantToRevisit"] = wantToRevisit
        }

        if id == nil {
            data["createdAt"] = now
        }

        try await ref.setData(data, merge: true)
    }
}

private extension FirestoreService {

    func authenticatedUserID() throws -> String {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw FirestoreServiceError.missingAuthenticatedUser
        }
        return userID
    }

    func userDocumentRef() throws -> DocumentReference {
        database.collection("users").document(try authenticatedUserID())
    }

    func normalizedNickname(_ nickname: String) -> String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func accordStrengthsForStorage(from perfume: FragellaPerfume) -> [String: String] {
        if !perfume.mainAccordStrengths.isEmpty {
            return perfume.mainAccordStrengths.reduce(into: [String: String]()) { result, pair in
                guard let canonical = ScentFamilyNormalizer.canonicalName(for: pair.key) else { return }
                let existingWeight: Double
                if
                    let storedRawValue = result[canonical],
                    let storedStrength = AccordStrength(rawDescription: storedRawValue)
                {
                    existingWeight = storedStrength.weight
                } else {
                    existingWeight = -1
                }

                if pair.value.weight > existingWeight {
                    result[canonical] = pair.value.rawValue
                }
            }
        }

        let fallbackStrengths: [AccordStrength] = [.dominant, .prominent, .moderate, .subtle]
        return Dictionary(
            uniqueKeysWithValues: perfume.mainAccords.enumerated().compactMap { index, accord in
                guard let canonical = ScentFamilyNormalizer.canonicalName(for: accord) else { return nil }
                let strength = index < fallbackStrengths.count ? fallbackStrengths[index] : .subtle
                return (canonical, strength.rawValue)
            }
        )
    }

    static func tasteAnalysisDictionary(from result: TasteAnalysisResult) -> [String: Any] {
        [
            "primary_profile_code": result.primaryProfileCode,
            "primary_profile_name": result.primaryProfileName,
            "secondary_profile_code": result.secondaryProfileCode,
            "secondary_profile_name": result.secondaryProfileName,
            "analysis_summary": result.analysisSummary,
            "evidence_tags": [
                "experience": result.evidenceTags.experience,
                "vibes": result.evidenceTags.vibes,
                "images": result.evidenceTags.images
            ],
            "recommendation_direction": [
                "preferred_impression": result.recommendationDirection.preferredImpression,
                "preferred_families": result.recommendationDirection.preferredFamilies,
                "intensity_level": result.recommendationDirection.intensityLevel,
                "safe_starting_point": result.recommendationDirection.safeStartingPoint
            ]
        ]
    }

    static func decodeTasteAnalysis(from dictionary: [String: Any]) throws -> TasteAnalysisResult {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try JSONDecoder().decode(TasteAnalysisResult.self, from: data)
    }

    static func looksLikeTasteAnalysisPayload(_ dictionary: [String: Any]) -> Bool {
        dictionary["primary_profile_code"] != nil
        || dictionary["recommendation_direction"] != nil
        || dictionary["analysis_summary"] != nil
    }
}
