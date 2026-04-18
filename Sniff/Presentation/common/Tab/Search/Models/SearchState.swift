//
//  SearchState.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//
    // SearchState.swift
    // 킁킁(Sniff) - 검색 화면 상태 정의

import Foundation

    // MARK: - SearchState
    // 검색 화면의 3가지 상태를 명확히 분리
    // 마치 향수의 탑/미들/베이스 노트처럼 — 각 레이어가 독립적이면서 전체 흐름을 구성

enum SearchState: Equatable {

        /// 초기 상태 — 최근 검색어 표시
    case initial

        /// 타이핑 중 — 연관 검색어 표시
    case suggesting(query: String)

        /// 검색 완료 — 결과 표시
    case result(query: String)

    var isInitial: Bool {
        if case .initial = self { return true }
        return false
    }

    var isSuggesting: Bool {
        if case .suggesting = self { return true }
        return false
    }

    var isResult: Bool {
        if case .result = self { return true }
        return false
    }

    var query: String? {
        switch self {
            case .initial:              return nil
            case .suggesting(let q):   return q
            case .result(let q):       return q
        }
    }
}

    // MARK: - SearchSection
    // 검색 결과 섹션 타입

enum SearchSection: Int, CaseIterable {
    case brand    = 0   // 브랜드 섹션
    case perfume  = 1   // 향수 섹션
}

    // MARK: - SuggestionItem
    // 연관 검색어 아이템 타입

enum SuggestionItem: Equatable {
    case brand(name: String)                    // 브랜드
    case perfume(name: String, brand: String)   // 향수명 + 브랜드

    var displayName: String {
        switch self {
            case .brand(let name):          return name
            case .perfume(let name, _):     return name
        }
    }

    var subTitle: String? {
        switch self {
            case .brand:                    return "브랜드"
            case .perfume(_, let brand):    return brand
        }
    }
}
