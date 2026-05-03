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

        /// 기본 탭 진입 상태 — 결과형 빈 화면
    case landing

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

    var isLanding: Bool {
        if case .landing = self { return true }
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
            case .landing:              return nil
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
    case brand(name: String, imageUrl: String?)                    // 브랜드
    case perfume(name: String, brand: String, imageUrl: String?)   // 향수명 + 브랜드

    /// 셀 표시 및 탭 후 검색창·최근 검색어에 사용되는 한글화된 이름
    var displayName: String {
        switch self {
            case .brand(let name, _):           return PerfumePresentationSupport.displayBrand(name)
            case .perfume(let name, _, _):      return PerfumePresentationSupport.displayPerfumeName(name)
        }
    }

    var subTitle: String? {
        switch self {
            case .brand:                        return AppStrings.DomainDisplay.Search.brandSubtitle
            case .perfume(_, let brand, _):     return brand
        }
    }

    /// 썸네일 이미지 URL
    var imageUrl: String? {
        switch self {
            case .brand(_, let url):            return url
            case .perfume(_, _, let url):       return url
        }
    }
}
