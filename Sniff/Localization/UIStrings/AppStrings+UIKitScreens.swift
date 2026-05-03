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
            static let guide = "오늘의 추천 향수는 취향 프로필에 따라 추천이 업데이트됩니다.\n취향 프로필은 보유 향수, 시향 기록에 따라 변경될 수 있습니다."
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
            static let registerTitle = "향수 등록"
            static let registerPlaceholder = "향수 이름이나 브랜드를 검색해보세요"
            static let registerConfirmMessage = "이 향수를 내 향수에 등록할까요?"
            static let registerAction = "등록하기"
            static let registerSuccess = "내 향수에 등록했어요"
            static let registerDuplicate = "이미 등록된 향수예요"
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
            static let addCollection = "보유향수 등록"
            static let addedCollection = "보유향수 등록됨"
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
            static let concentrationInfoTitle = "농도 정보"
            static let concentrationInfoBody = "향수의 농도에 따라 향의 진함과 지속 시간이 달라져요."
            static let scentFamilyInfoTitle = "향 계열 정보"
            static let scentFamilyInfoBody = "향의 성격을 나누는 기준이에요. 선호하는 계열을 선택하면 더 잘 맞는 향수를 찾는 데 도움이 돼요."

            static func applyCount(_ count: Int) -> String {
                "\(count)개 향수 보기"
            }
        }
    }
}
