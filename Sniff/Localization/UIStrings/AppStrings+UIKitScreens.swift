//
//  AppStrings+UIKitScreens.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum UIKitScreens {
        static let confirm = "확인"
        static let cancel = "취소"
        static let error = "오류"

        enum Home {
            static let title = AppStrings.AppShell.appName
            static let profile = "취향 프로필"
            static let profileLoading = "분석 중..."
            static let best = "베스트"
            static let recommendations = "추천 향수"
            static let guide = "추천은 취향 분석과 시향 기록, 등록한 향수를 기반으로 계속 업데이트 됩니다."
            static let routePerfumeRegister = "향수 등록 화면으로 연결할 수 있어요."
            static let routeTastingNote = "시향기 작성 화면으로 연결할 수 있어요."
            static let routeTasteReport = "취향 리포트 화면으로 연결할 수 있어요."
            static let sampleCard = "현재 카드는 샘플 데이터예요."
            static let likeSavedClose = "닫기"
            static let likeSavedOpen = "LIKE 향수 보기"

            static func likeSaved(_ perfumeName: String) -> String {
                "\(perfumeName)을 LIKE 향수에 저장했어요."
            }
        }

        enum Search {
            static let placeholder = "향수명 또는 브랜드를 검색하세요"
            static let sortRecommended = "추천순 ▾"
            static let recentTitle = "최근 검색어"
            static let clearAll = "모두 지우기"
            static let noRecent = "최근 검색어가 없어요"
            static let likeSaveFailed = "LIKE 향수 저장에 실패했어요."
            static let landingBrandMessage = "브랜드 검색 결과가 없어요."
            static let landingPerfumeMessage = "향수 검색 결과가 없어요."
            static let landingGuideMessage = "검색어를 입력하면 관련 브랜드 결과를 보여드려요."

            static func brandCount(_ count: Int) -> String {
                "브랜드 \(count)개"
            }

            static func perfumeCount(_ count: Int) -> String {
                "향수 \(count)개"
            }

            static func noBrandResults(_ query: String) -> String {
                "\"\(query)\"에 대한 브랜드 검색 결과가 없어요."
            }

            static func noResults(_ query: String) -> String {
                "\"\(query)\"에 대한 향수 검색 결과가 없어요."
            }
        }

        enum PerfumeDetail {
            static let usage = "사용감"
            static let accords = "향 계열"
            static let notes = "노트"
            static let season = "계절"
            static let longevity = "지속력"
            static let sillage = "확산력"
            static let topNotes = "탑"
            static let middleNotes = "미들"
            static let baseNotes = "베이스"
            static let imagePlaceholder = "이미지 준비중입니다"
            static let addCollection = "향수 등록"
            static let addedCollection = "향수 등록됨"
            static let addTasting = "시향기록 남기기"
            static let tastingSavedTitle = "시향 기록 저장 완료"

            static func tastingSaved(_ perfumeName: String) -> String {
                "\(perfumeName) 시향 기록이 저장되었습니다."
            }
        }

        enum Filter {
            static let title = "필터"
            static let reset = "초기화"
            static let apply = "향수 보기"
            static let scentFamily = "향 계열"
            static let moodImage = "분위기 / 이미지"
            static let concentration = "농도"
            static let season = "계절"
            static let concentrationInfoTitle = "농도 설명"
            static let scentFamilyInfoTitle = "향 계열 설명"
            static let scentFamilyInfoBody = "Fragrance Wheel 기준 계열이에요. 각 계열이 어떤 향인지 빠르게 확인할 수 있어요."

            static func applyCount(_ count: Int) -> String {
                "향수 \(count)개 보기"
            }
        }
    }
}
