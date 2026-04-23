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
    func analyzeTaste(input: TasteAnalysisInput) async throws -> TasteAnalysisResult
    func checkNicknameAvailability(_ nickname: String) async throws -> Bool
    func saveUserProfile(nickname: String, tasteAnalysis: TasteAnalysisResult) async throws
}
