//
//  UserTasteRepositoryType.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import RxSwift

protocol UserTasteRepositoryType {
    func fetchTasteAnalysis() -> Single<TasteAnalysisResult>
    func fetchTasteProfileHistory() -> Single<[TasteProfileHistoryEntry]>
    func recordTasteProfileHistoryIfNeeded(
        profile: UserTasteProfile,
        collectionCount: Int,
        tastingCount: Int
    ) -> Single<[TasteProfileHistoryEntry]>
    func analyzeTaste(input: TasteAnalysisInput) async throws -> TasteAnalysisResult
    func reanalyzeTasteFromHistory() async throws -> TasteAnalysisResult
    func applyHistoricalProfile(_ entry: TasteProfileHistoryEntry) async throws
    func checkNicknameAvailability(_ nickname: String) async throws -> Bool
    func saveUserProfile(
        nickname: String,
        tasteAnalysis: TasteAnalysisResult,
        experienceLevel: String?
    ) async throws
}
