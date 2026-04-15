//
//  UserTasteRepository.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//

import Foundation
import RxSwift

protocol UserTasteRepositoryType {
    func fetchTasteAnalysis() -> Single<TasteAnalysisResult>
    func analyzeTaste(input: TasteAnalysisInput) async throws -> TasteAnalysisResult
    func saveUserProfile(nickname: String, tasteAnalysis: TasteAnalysisResult) async throws
}

final class UserTasteRepository: UserTasteRepositoryType {

    private let geminiService: GeminiTasteAnalysisService?
    private let firestoreService: FirestoreService

    init(
        geminiService: GeminiTasteAnalysisService? = nil,
        firestoreService: FirestoreService = .shared
    ) {
        self.firestoreService = firestoreService

        if let geminiService {
            self.geminiService = geminiService
        } else {
            self.geminiService = try? GeminiTasteAnalysisService(
                apiKey: AppSecrets.geminiAPIKey()
            )
        }
    }

    func fetchTasteAnalysis() -> Single<TasteAnalysisResult> {
        Single.create { [weak self] single in
            guard let self else {
                single(.failure(AppSecretsError.missingValue("FIRESTORE_SERVICE")))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await self.firestoreService.fetchTasteAnalysis()
                    single(.success(result))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func analyzeTaste(input: TasteAnalysisInput) async throws -> TasteAnalysisResult {
        guard let geminiService else {
            throw AppSecretsError.missingValue("GEMINI_API_KEY")
        }

        return try await geminiService.requestTasteAnalysis(input: input)
    }

    func saveUserProfile(nickname: String, tasteAnalysis: TasteAnalysisResult) async throws {
        try await firestoreService.saveUserProfile(
            nickname: nickname,
            tasteAnalysis: tasteAnalysis
        )
    }
}
