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
    case invalidUserProfile
    case nicknameCheckUnavailable
    case profileSaveUnavailable

    var errorDescription: String? {
        switch self {
        case .missingAuthenticatedUser:
            return "로그인된 사용자 정보를 찾을 수 없어요"
        case .invalidTasteAnalysisData:
            return "저장된 취향 분석 데이터를 읽을 수 없어요"
        case .invalidUserProfile:
            return "저장된 사용자 정보를 읽을 수 없어요"
        case .nicknameCheckUnavailable:
            return "지금은 닉네임 중복 확인을 할 수 없어요. 잠시 후 다시 시도해주세요"
        case .profileSaveUnavailable:
            return "지금은 프로필을 저장할 수 없어요. 잠시 후 다시 시도해주세요"
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
    do {
        let snapshot = try await database.collection("users")
            .whereField("nicknameLowercased", isEqualTo: normalizedNickname)
            .getDocuments()

        return snapshot.documents.allSatisfy { $0.documentID == currentUserID }
    } catch let error as NSError {
        guard error.domain == FirestoreErrorDomain else { throw error }

        if error.code == FirestoreErrorCode.permissionDenied.rawValue {
            throw FirestoreServiceError.nicknameCheckUnavailable
        }

        throw error
    }
    }

    func saveUserProfile(
        nickname: String,
        tasteAnalysis: TasteAnalysisResult,
        experienceLevel: String? = nil
    ) async throws {
        let now = FieldValue.serverTimestamp()
        let ref = try userDocumentRef()
        let snapshot = try await ref.getDocument()

        var data: [String: Any] = [
            "nickname": nickname,
            "nicknameLowercased": normalizedNickname(nickname),
            "tasteAnalysis": Self.tasteAnalysisDictionary(from: tasteAnalysis),
            "onboardingCompleted": true,
            "updatedAt": now
        ]

        if let experienceLevel, !experienceLevel.isEmpty {
            data["experienceLevel"] = experienceLevel
        }

        if snapshot.exists {
            if let createdAt = snapshot.data()?["createdAt"] {
                data["createdAt"] = createdAt
            }
        } else {
            data["createdAt"] = now
        }

        do {
            try await ref.setData(data, merge: true)
        } catch let error as NSError {
            guard error.domain == FirestoreErrorDomain else { throw error }

            if error.code == FirestoreErrorCode.permissionDenied.rawValue {
                throw FirestoreServiceError.profileSaveUnavailable
            }

            throw error
        }
    }

    func fetchUserProfile() async throws -> SniffUser {
        let snapshot = try await userDocumentRef().getDocument()
        let data = snapshot.data() ?? [:]
        let nickname = (data["nickname"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !nickname.isEmpty else {
            throw FirestoreServiceError.invalidUserProfile
        }

        // contactEmail 필드 우선 사용, 없으면 Firebase Auth 이메일로 폴백
        let contactEmail = (data["contactEmail"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedEmail = (contactEmail?.isEmpty == false) ? contactEmail : Auth.auth().currentUser?.email

        return SniffUser(
            uid: try authenticatedUserID(),
            nickname: nickname,
            email: resolvedEmail,
            onboardingCompleted: data["onboardingCompleted"] as? Bool,
            experienceLevel: data["experienceLevel"] as? String
        )
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

    func deleteCollectionItems(ids: [String]) async throws {
        guard !ids.isEmpty else { return }

        let collectionRef = try userDocumentRef().collection("collection")
        let batch = database.batch()

        ids.forEach { id in
            batch.deleteDocument(collectionRef.document(id))
        }

        try await batch.commit()
    }

    func fetchLikedPerfumes() async throws -> [LikedPerfume] {
        let snapshot = try await userDocumentRef()
            .collection("likes")
            .order(by: "likedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap(Self.makeLikedPerfume)
    }

    func removeLikedPerfume(id: String) async throws {
        try await userDocumentRef()
            .collection("likes")
            .document(id)
            .delete()
    }

    func saveLikedPerfume(_ perfume: Perfume) async throws {
        let now = FieldValue.serverTimestamp()
        let ref = try userDocumentRef()
            .collection("likes")
            .document(perfume.id)

        let data: [String: Any] = [
            "name": perfume.name,
            "brand": perfume.brand,
            "imageUrl": perfume.imageUrl as Any,
            "mainAccords": perfume.mainAccords,
            "likedAt": now
        ]

        try await ref.setData(data, merge: true)
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
        _ perfume: Perfume,
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

    func deleteCollectedPerfume(id: String) async throws {
        try await userDocumentRef()
            .collection("collection")
            .document(id)
            .delete()
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

    static func accordStrengthsForStorage(from perfume: Perfume) -> [String: String] {
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

    private static func makeLikedPerfume(from document: QueryDocumentSnapshot) -> LikedPerfume? {
        let data = document.data()
        let name = (data["name"] as? String) ?? (data["perfumeName"] as? String)
        let brand = (data["brand"] as? String) ?? (data["brandName"] as? String)

        guard
            let name,
            let brand
        else { return nil }
        let timestamp = data["likedAt"] as? Timestamp
        let rawMainAccords = data["mainAccords"] as? [String] ?? []
        let legacyAccords = [data["scentFamily"] as? String, data["scentFamily2"] as? String]
            .compactMap { $0 }
        let mainAccords = ScentFamilyNormalizer.canonicalNames(
            for: rawMainAccords.isEmpty ? legacyAccords : rawMainAccords
        )
        return LikedPerfume(
            id: document.documentID,
            name: name,
            brand: brand,
            scentFamily: data["scentFamily"] as? String,
            scentFamily2: data["scentFamily2"] as? String,
            imageURL: data["imageUrl"] as? String ?? data["imageURL"] as? String,
            mainAccords: mainAccords,
            likedAt: timestamp?.dateValue()
        )
    }

    static func looksLikeTasteAnalysisPayload(_ dictionary: [String: Any]) -> Bool {
        dictionary["primary_profile_code"] != nil
        || dictionary["primary_profile_name"] != nil
        || dictionary["secondary_profile_code"] != nil
        || dictionary["secondary_profile_name"] != nil
        || dictionary["recommendation_direction"] != nil
        || dictionary["analysis_summary"] != nil
    }
}
