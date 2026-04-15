//
//  AppStrings.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//

import Foundation

enum AppStrings {

        // MARK: - 온보딩
    enum Onboarding {
        static let experienceTitle = "현재 당신의\n향수 경험을 알려주세요"
        static let tasteTitle = "향수로 표현하고 싶은\n느낌을 골라주세요"
        static let vibeSection = "✨ 분위기"
        static let imageSection = "🌸 향의 느낌"
        static let next = "다음"
        static let complete = "취향 분석 시작하기"
        static let analyzing = "취향을 분석하고 있어요..."

        enum Experience {
            static let beginner = "향수, 이제 막 시작했어요"
            static let beginnerDesc = "계열이나 노트는 아직 잘 몰라요"
            static let casual = "향수, 가끔 뿌리는 편이에요"
            static let casualDesc = "계열 이름 정도는 들어본 것 같아요"
            static let expert = "향수, 꽤 잘 아는 편이에요"
            static let expertDesc = "노트 구성이나 계열도 구분할 수 있어요"
        }

        enum Result {
            static func title(nickname: String) -> String {
                "\(nickname)님의 향수 취향\n분석이 완료됐어요 🌸"
            }
            static let subtitle = "나만의 향수를 찾아볼게요"
            static let cta = "나에게 맞는 향수 보기"
        }
    }

        // MARK: - 홈
    enum Home {
        static func greeting(nickname: String) -> String {
            "\(nickname)님의 취향에 맞는\n향수를 찾아왔어요 🌸"
        }
        static let recommendTitle = "오늘의 추천 향수"
        static let recommendBasis = "취향 분석 기반 추천이에요"
        static let shortcutPerfume = "향수 등록"
        static let shortcutTasting = "시향기 등록"
        static let shortcutReport = "취향 리포트"
        static let emptyRecommend = "취향 분석을 완료하면\n맞춤 향수를 추천해드려요 🌿"
    }

        // MARK: - 검색
    enum Search {
        static let placeholder = "향수명 또는 브랜드를 검색해보세요"
        static let recentTitle = "최근 검색어"
        static let recentClear = "모두 지우기"
        static let emptyResult = "조건에 맞는 향수를 찾지 못했어요. 필터를 바꿔볼까요?"
        static let filterTitle = "필터"
        static let filterReset = "초기화"
        static let filterApply = "적용하기"
    }

        // MARK: - 시향기
    enum TastingNote {
        static let emptyList = "아직 기록이 없어요. 오늘 맡은 향수를 기록해보세요 🌿"
        static let searchPlaceholder = "향수명을 입력해주세요"
        static let contentPlaceholder = "향수를 맡은 느낌을 자유롭게 기록해보세요 ✍️"
        static let saveButton = "기록 저장하기"
        static let cancelButton = "나중에 할게요"
        static let deleteConfirm = "기록을 삭제할까요? 한번 삭제하면 되돌릴 수 없어요"
        static let deleteButton = "삭제할게요"
        static let cancelDelete = "아니요, 유지할게요"

        static func firstRecord(nickname: String) -> String {
            "첫 번째 시향기를 기록했어요!\n\(nickname)님의 향수 여정이 시작됐네요 🌸"
        }
        static let savedSuccess = "기록이 저장됐어요 ✍️"
        static let updatedSuccess = "기록이 수정됐어요 ✅"
    }

        // MARK: - 마이페이지
    enum MyPage {
        static let collectionTitle = "내 향수 컬렉션"
        static let collectionMore = "전체 보기"
        static let tasteCardTitle = "나의 취향 프로필"

        enum TasteCard {
            static let step0Title = "아직 취향 분석이 없어요"
            static let step0Cta = "취향 분석 시작하기"
            static func step2Message(count: Int) -> String {
                "향수를 \(count)개 기록했어요! 더 많이 기록할수록 취향이 더 정확해져요 🌿"
            }
            static func step3Update(nickname: String) -> String {
                "\(nickname)님의 취향이 더 선명해졌어요 ✨"
            }
        }
    }

        // MARK: - 컬렉션
    enum Collection {
        static let emptyTitle = "아직 등록된 향수가 없어요"
        static let emptyMessage = "첫 번째 향수를 찾아볼까요? 🔍"
        static let addSuccess = "컬렉션에 추가됐어요 🌸"
        static let removeConfirm = "컬렉션에서 제거할까요?"
        static let removeButton = "제거할게요"
        static let cancelButton = "아니요, 유지할게요"
    }

        // MARK: - 환경설정
    enum Settings {
        static let logoutTitle = "로그아웃 할까요?"
        static let logoutConfirm = "로그아웃"
        static let logoutCancel = "아니요"
        static let deleteAccountTitle = "정말 떠나실 건가요? 😢"
        static let deleteAccountMessage = "모든 기록과 취향 데이터가 사라져요"
        static let deleteAccountConfirm = "떠날게요"
        static let deleteAccountCancel = "아니요, 남을게요"
    }

        // MARK: - 공통 에러
    enum Error {
        static let network = "잠깐, 연결이 끊겼나봐요. 다시 시도해볼까요?"
        static let retry = "다시 시도하기"
        static let unknown = "앗, 문제가 생겼어요. 잠시 후 다시 시도해주세요"
        static let loading = "불러오고 있어요 🌿"
        static let perfumeLoading = "향수를 찾고 있어요 🌸"
        static let analyzing = "취향에 맞는 향수를 찾고 있어요..."
    }

        // MARK: - 닉네임
    enum Nickname {
        static let title = "킁킁에서 사용할\n이름을 알려주세요"
        static let placeholder = "닉네임을 입력해주세요"
        static let hint = "한글/영문/숫자 2~10자로 입력해주세요"
        static let confirm = "시작하기"
        static func welcome(nickname: String) -> String {
            "반가워요, \(nickname)님! 🌸\n취향에 맞는 향수를 찾아드릴게요"
        }
    }
}
