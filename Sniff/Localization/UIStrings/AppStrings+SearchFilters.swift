//
//  AppStrings+SearchFilters.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum DomainDisplay {}
}

extension AppStrings.DomainDisplay {
    enum SearchFilters {
        nonisolated static let parfum = "퍼퓸"
        nonisolated static let eauDeParfum = "오드퍼퓸(EDP)"
        nonisolated static let eauDeToilette = "오드뚜왈렛(EDT)"
        nonisolated static let eauDeCologne = "오드콜로뉴(EDC)"
        nonisolated static let eauFraiche = "오프레시"

        nonisolated static let spring = "봄"
        nonisolated static let summer = "여름"
        nonisolated static let fall = "가을"
        nonisolated static let winter = "겨울"

        nonisolated static let parfumDescription = "오일 함량이 가장 높아 향이 진하고 오래 유지되는 편이에요."
        nonisolated static let eauDeParfumDescription = "일상에서 가장 무난하게 쓰기 좋고 지속력도 비교적 안정적이에요."
        nonisolated static let eauDeToiletteDescription = "EDP보다 가볍고 산뜻해서 데일리로 부담 없이 쓰기 좋아요."
        nonisolated static let eauDeCologneDescription = "향이 가장 가볍고 지속 시간이 짧아 리프레시용에 가까워요."
        nonisolated static let eauFraicheDescription = "아주 옅고 가벼운 타입으로 짧게 향을 더하는 느낌에 가까워요."

        nonisolated static let sortRecommended = "추천순"
        nonisolated static let sortNameAsc = "이름순 (A-Z)"
        nonisolated static let sortNameDesc = "이름역순 (Z-A)"

        nonisolated static let citrusDescription = "레몬과 베르가못처럼 상큼하고 밝은 계열"
        nonisolated static let fruityDescription = "과즙감 있고 달콤한 생기가 느껴지는 계열"
        nonisolated static let greenDescription = "풀잎과 허브처럼 싱그럽고 내추럴한 계열"
        nonisolated static let waterDescription = "물기 어린 시원함과 맑은 공기가 느껴지는 계열"
        nonisolated static let aromaticDescription = "허브와 잎사귀처럼 산뜻하고 깔끔한 계열"
        nonisolated static let floralDescription = "꽃향 중심의 화사하고 우아한 계열"
        nonisolated static let softFloralDescription = "보송하고 부드러운 꽃향이 감도는 계열"
        nonisolated static let floralAmberDescription = "꽃향에 따뜻한 앰버 기운이 더해진 계열"
        nonisolated static let softAmberDescription = "부드럽고 달콤하게 감도는 앰버 계열"
        nonisolated static let amberDescription = "따뜻하고 묵직한 잔향이 느껴지는 계열"
        nonisolated static let woodsDescription = "나무결처럼 차분하고 자연스러운 우디 계열"
        nonisolated static let woodyAmberDescription = "우디와 앰버가 겹쳐 따뜻하고 고급스러운 계열"
        nonisolated static let mossyWoodsDescription = "이끼와 흙내음이 감도는 깊고 차분한 우디 계열"
        nonisolated static let dryWoodsDescription = "건조하고 또렷한 나무 향이 중심인 우디 계열"

        nonisolated static func summaryLabel(_ first: String, _ remaining: Int) -> String {
            "\(first) 외 \(remaining)개"
        }
    }

    enum Search {
        nonisolated static let brandSubtitle = "브랜드"
    }
}
