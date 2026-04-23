//
//  UserTasteRepository.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//

import Foundation
import RxSwift

final class UserTasteRepository: UserTasteRepositoryType {

    private enum CacheKey {
        static let latestTasteAnalysis = "sniff.latestTasteAnalysis"
    }

    private let geminiService: GeminiTasteAnalysisService?
    private let firestoreService: FirestoreService
    private let defaults: UserDefaults

    init(
        geminiService: GeminiTasteAnalysisService? = nil,
        firestoreService: FirestoreService? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.firestoreService = firestoreService ?? .shared
        self.defaults = defaults

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
                    self.cacheTasteAnalysis(result)
                    single(.success(result))
                } catch {
                    if let cached = self.cachedTasteAnalysis() {
                        single(.success(cached))
                    } else {
                        single(.failure(error))
                    }
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

        let result = try await geminiService.requestTasteAnalysis(input: input)
        cacheTasteAnalysis(result)
        return result
    }

    func checkNicknameAvailability(_ nickname: String) async throws -> Bool {
        try await firestoreService.isNicknameAvailable(nickname)
    }

    func saveUserProfile(
        nickname: String,
        tasteAnalysis: TasteAnalysisResult,
        experienceLevel: String? = nil
    ) async throws {
        try await firestoreService.saveUserProfile(
            nickname: nickname,
            tasteAnalysis: tasteAnalysis,
            experienceLevel: experienceLevel
        )
        cacheTasteAnalysis(tasteAnalysis)
    }

    private func cacheTasteAnalysis(_ result: TasteAnalysisResult) {
        guard let data = try? JSONEncoder().encode(result) else { return }
        defaults.set(data, forKey: CacheKey.latestTasteAnalysis)
    }

    private func cachedTasteAnalysis() -> TasteAnalysisResult? {
        guard let data = defaults.data(forKey: CacheKey.latestTasteAnalysis) else { return nil }
        return try? JSONDecoder().decode(TasteAnalysisResult.self, from: data)
    }
}
