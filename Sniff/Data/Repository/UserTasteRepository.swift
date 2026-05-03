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

    private enum NarrativeRefreshRule {
        static let minimumRecordCount = 5
        static let minimumMemoLength = 20
    }

    private let geminiService: GeminiTasteAnalysisService?
    private let firestoreService: FirestoreService
    private let defaults: UserDefaults
    private let aggregator = PreferenceAggregator()

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

    func fetchTasteProfileHistory() -> Single<[TasteProfileHistoryEntry]> {
        Single.create { [weak self] single in
            guard let self else {
                single(.success([]))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let history = try await self.firestoreService.fetchTasteProfileHistory()
                    single(.success(history))
                } catch {
                    single(.success([]))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func recordTasteProfileHistoryIfNeeded(
        profile: UserTasteProfile,
        collectionCount: Int,
        tastingCount: Int
    ) -> Single<[TasteProfileHistoryEntry]> {
        Single.create { [weak self] single in
            guard let self else {
                single(.success([]))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let history = try await self.firestoreService.recordTasteProfileHistoryIfNeeded(
                        profile: profile,
                        collectionCount: collectionCount,
                        tastingCount: tastingCount
                    )
                    single(.success(history))
                } catch {
                    single(.success([]))
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

    func reanalyzeTasteFromHistory() async throws -> TasteAnalysisResult {
        guard let geminiService else {
            throw AppSecretsError.missingValue("GEMINI_API_KEY")
        }

        async let onboardingAnalysis = firestoreService.fetchTasteAnalysis()
        async let collection = firestoreService.fetchCollection()
        async let tastingRecords = firestoreService.fetchTastingRecords()
        async let userProfile = firestoreService.fetchUserProfile()

        let baseAnalysis = try await onboardingAnalysis
        let collectionItems = try await collection
        let recordItems = try await tastingRecords
        let user = try await userProfile

        let aggregatedProfile = aggregator.aggregate(
            onboarding: baseAnalysis,
            collection: collectionItems,
            tastingRecords: recordItems
        )

        guard shouldRefreshNarrative(with: recordItems) else {
            return baseAnalysis
        }

        let enrichedInput = TasteAnalysisInput(
            experience: baseAnalysis.evidenceTags.experience,
            vibes: baseAnalysis.evidenceTags.vibes,
            images: baseAnalysis.evidenceTags.images,
            aggregatedProfile: (!collectionItems.isEmpty || !recordItems.isEmpty)
                ? AggregatedProfileForGemini(profile: aggregatedProfile)
                : nil,
            records: TastingRecordForGemini.supportingRecords(from: recordItems)
        )

        let refreshedAnalysis = try await geminiService.requestTasteAnalysis(input: enrichedInput)
        try await saveUserProfile(
            nickname: user.nickname,
            tasteAnalysis: refreshedAnalysis,
            experienceLevel: user.experienceLevel
        )

        // 재분석 후 변경된 프로필을 히스토리에 기록
        // title 또는 대표 계열이 달라진 경우에만 Firestore에 새 항목 추가
        let updatedProfile = aggregator.aggregate(
            onboarding: refreshedAnalysis,
            collection: collectionItems,
            tastingRecords: recordItems
        )
        _ = try? await firestoreService.recordTasteProfileHistoryIfNeeded(
            profile: updatedProfile,
            collectionCount: collectionItems.count,
            tastingCount: recordItems.count
        )

        return refreshedAnalysis
    }

    func applyHistoricalProfile(_ entry: TasteProfileHistoryEntry) async throws {
        // Firestore taste_title 업데이트
        try await firestoreService.applyHistoricalProfile(title: entry.title)
        // UserDefaults 캐시 초기화 → 다음 fetch 시 Firestore에서 최신 데이터 로드
        defaults.removeObject(forKey: CacheKey.latestTasteAnalysis)
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

    private func shouldRefreshNarrative(with records: [TastingRecord]) -> Bool {
        guard records.count >= NarrativeRefreshRule.minimumRecordCount else { return false }

        return records.contains { record in
            let memoLength = record.memo?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .count ?? 0
            return memoLength >= NarrativeRefreshRule.minimumMemoLength
        }
    }
}
