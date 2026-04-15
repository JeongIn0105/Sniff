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
    case missingDocument(String)

    var errorDescription: String? {
        switch self {
        case .missingDocument(let path):
            return "\(path) 문서를 찾을 수 없어요"
        }
    }
}

final class FirestoreService {

    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    private init() {}

    func saveUserProfile(
        nickname: String,
        tasteAnalysis: TasteAnalysisResult
    ) async throws {
        let now = FieldValue.serverTimestamp()
        let userRef = userDocumentRef()

        try await userRef.setData([
            "nickname": nickname,
            "createdAt": now,
            "updatedAt": now,
            "tasteAnalysis": Self.tasteAnalysisDictionary(from: tasteAnalysis),
            "recommendationMeta": [
                "profileVersion": 1,
                "lastAnalyzedAt": now
            ]
        ], merge: true)
    }

    func fetchTasteAnalysis() async throws -> TasteAnalysisResult {
        let snapshot = try await userDocumentRef().getDocument()

        guard snapshot.exists else {
            throw FirestoreServiceError.missingDocument("users/\(currentUserID())")
        }

        guard
            let data = snapshot.data(),
            let tasteAnalysis = data["tasteAnalysis"] as? [String: Any]
        else {
            throw FirestoreServiceError.missingDocument("users/\(currentUserID()).tasteAnalysis")
        }

        return try Self.decodeTasteAnalysis(from: tasteAnalysis)
    }

    func fetchCollection() async throws -> [CollectedPerfume] {
        let snapshot = try await userDocumentRef()
            .collection("collection")
            .order(by: "addedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap(Self.makeCollectedPerfume)
    }

    func fetchTastingRecords() async throws -> [TastingRecord] {
        let snapshot = try await userDocumentRef()
            .collection("tastingRecords")
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap(Self.makeTastingRecord)
    }

    private func userDocumentRef() -> DocumentReference {
        db.collection("users").document(currentUserID())
    }

    private func currentUserID() -> String {
        Auth.auth().currentUser?.uid ?? "debug-user"
    }

    private static func tasteAnalysisDictionary(from result: TasteAnalysisResult) -> [String: Any] {
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

    private static func decodeTasteAnalysis(from data: [String: Any]) throws -> TasteAnalysisResult {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(TasteAnalysisResult.self, from: jsonData)
    }

    private static func makeCollectedPerfume(from document: QueryDocumentSnapshot) -> CollectedPerfume? {
        let data = document.data()

        guard
            let name = data["name"] as? String,
            let brand = data["brand"] as? String
        else {
            return nil
        }

        let timestamp = data["addedAt"] as? Timestamp

        return CollectedPerfume(
            id: document.documentID,
            name: name,
            brand: brand,
            scentFamily: data["scentFamily"] as? String,
            scentFamily2: data["scentFamily2"] as? String,
            createdAt: timestamp?.dateValue()
        )
    }

    private static func makeTastingRecord(from document: QueryDocumentSnapshot) -> TastingRecord? {
        let data = document.data()

        guard
            let perfumeName = data["perfumeName"] as? String,
            let brandName = data["brandName"] as? String,
            let rating = data["rating"] as? Int,
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }

        return TastingRecord(
            id: document.documentID,
            perfumeName: perfumeName,
            brandName: brandName,
            mainAccords: data["mainAccords"] as? [String] ?? [],
            rating: rating,
            moodTags: data["moodTags"] as? [String] ?? [],
            updatedAt: updatedAt
        )
    }
}
