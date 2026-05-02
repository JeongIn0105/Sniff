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

    // 히스토리 항목을 현재 프로필로 적용 - taste_title만 업데이트
    func applyHistoricalProfile(title: String) async throws {
        let ref = try userDocumentRef()
        try await ref.updateData(["tasteAnalysis.taste_title": title])
    }

    func fetchTasteProfileHistory(limit: Int = 10) async throws -> [TasteProfileHistoryEntry] {
        let snapshot = try await userDocumentRef()
            .collection("profileHistory")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap(Self.makeTasteProfileHistoryEntry)
    }

    func recordTasteProfileHistoryIfNeeded(
        profile: UserTasteProfile,
        collectionCount: Int,
        tastingCount: Int
    ) async throws -> [TasteProfileHistoryEntry] {
        let historyRef = try userDocumentRef().collection("profileHistory")
        let latest = try await historyRef
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .getDocuments()
            .documents
            .first
            .flatMap { Self.makeTasteProfileHistoryEntry(from: $0) }

        let title = profile.displayTitle
        let families = Array(profile.displayFamilies.prefix(2))

        if latest?.title == title && latest?.families == families {
            return try await fetchTasteProfileHistory()
        }

        let now = FieldValue.serverTimestamp()
        let data: [String: Any] = [
            "title": title,
            "families": families,
            "scentVector": profile.scentVector,
            "collectionCount": collectionCount,
            "tastingCount": tastingCount,
            "stage": profile.stage.historyValue,
            "createdAt": now
        ]

        try await historyRef.document().setData(data, merge: false)
        return try await fetchTasteProfileHistory()
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
            .document(perfume.collectionDocumentID)

        // nil 옵셔널은 Firestore에 null로 전송되면 보안 규칙의
        // (!('imageUrl' in data) || data.imageUrl is string) 검증 실패 → PERMISSION_DENIED
        var data: [String: Any] = [
            "name": perfume.name,
            "brand": perfume.brand,
            "mainAccords": perfume.mainAccords,
            "likedAt": now
        ]

        if let imageUrl = perfume.imageUrl { data["imageUrl"] = imageUrl }

        try await ref.setData(data, merge: false)
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
            .document(perfume.collectionDocumentID)

        // nil 옵셔널은 Firestore에 null로 전송되면 보안 규칙의
        // (!('field' in data) || data.field is string) 검증 실패 → PERMISSION_DENIED
        // 따라서 nil인 옵셔널 필드는 딕셔너리에 포함하지 않음
        var data: [String: Any] = [
            "name": perfume.name,
            "brand": perfume.brand,
            "mainAccords": perfume.mainAccords,
            "accordStrengths": Self.accordStrengthsForStorage(from: perfume),
            "addedAt": now,
            "updatedAt": now
        ]

        if let imageUrl = perfume.imageUrl { data["imageUrl"] = imageUrl }
        if let concentration = perfume.concentration, !concentration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["concentration"] = concentration
        }
        if let gender = perfume.gender { data["gender"] = gender }
        if let memo, !memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["memo"] = memo
        }
        try await ref.setData(data, merge: false)
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
            "taste_title": result.tasteTitle as Any,
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

    static func makeTasteProfileHistoryEntry(from document: QueryDocumentSnapshot) -> TasteProfileHistoryEntry? {
        let data = document.data()
        guard
            let title = data["title"] as? String,
            let families = data["families"] as? [String],
            let scentVector = doubleDictionary(from: data["scentVector"]),
            let collectionCount = intValue(from: data["collectionCount"]),
            let tastingCount = intValue(from: data["tastingCount"]),
            let stage = data["stage"] as? String
        else {
            return nil
        }

        return TasteProfileHistoryEntry(
            id: document.documentID,
            title: FragranceProfileText.validatedTasteTitle(title) ?? title,
            families: families,
            scentVector: scentVector,
            collectionCount: collectionCount,
            tastingCount: tastingCount,
            stage: stage,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue()
        )
    }

    static func doubleDictionary(from value: Any?) -> [String: Double]? {
        guard let dictionary = value as? [String: Any] else { return nil }

        return dictionary.reduce(into: [String: Double]()) { result, item in
            if let value = item.value as? Double {
                result[item.key] = value
            } else if let value = item.value as? NSNumber {
                result[item.key] = value.doubleValue
            }
        }
    }

    static func intValue(from value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }

        if let value = value as? NSNumber {
            return value.intValue
        }

        return nil
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
        let seasonRanking: [SeasonRankingEntry] = (data["seasonRanking"] as? [[String: Any]] ?? [])
            .compactMap { entry in
                guard let name = entry["name"] as? String, let score = entry["score"] as? Double else { return nil }
                return SeasonRankingEntry(name: name, score: score)
            }

        return LikedPerfume(
            id: document.documentID,
            name: name,
            brand: brand,
            scentFamily: data["scentFamily"] as? String,
            scentFamily2: data["scentFamily2"] as? String,
            imageURL: data["imageUrl"] as? String ?? data["imageURL"] as? String,
            mainAccords: mainAccords,
            likedAt: timestamp?.dateValue(),
            topNotes: data["topNotes"] as? [String],
            middleNotes: data["middleNotes"] as? [String],
            baseNotes: data["baseNotes"] as? [String],
            seasonRanking: seasonRanking,
            concentration: data["concentration"] as? String,
            longevity: data["longevity"] as? String,
            sillage: data["sillage"] as? String
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
