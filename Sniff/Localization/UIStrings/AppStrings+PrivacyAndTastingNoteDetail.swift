//
//  AppStrings+PrivacyAndTastingNoteDetail.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum PrivacyPolicy {
        nonisolated static let title = "개인정보처리방침"
        nonisolated static let updatedAt = "최종 업데이트: 2026년 5월"
        nonisolated static let bullet = "•"
        nonisolated static let emailPrefix = "이메일:"

        nonisolated static let sections: [PolicySectionContent] = [
            .init(
                title: "1. 수집하는 개인정보 항목",
                body: "킁킁은 서비스 제공을 위해 다음과 같은 개인정보 및 서비스 이용 정보를 수집할 수 있습니다.",
                bullets: [
                    "이메일 주소 (Apple 또는 Google 로그인 시 제공될 수 있음)",
                    "닉네임 (사용자 직접 설정)",
                    "향수 취향 데이터 (온보딩/앱 내 입력)",
                    "보유 향수, LIKE 향수, 시향 기록 등 사용자가 앱 내에서 직접 저장한 데이터",
                    "서비스 이용 과정에서 생성되는 최소한의 접속 및 이용 기록"
                ]
            ),
            .init(
                title: "2. 개인정보의 이용 목적",
                body: "수집된 개인정보는 다음 목적에 활용됩니다.",
                bullets: [
                    "회원 식별 및 로그인 상태 유지",
                    "개인 맞춤형 향수 추천 및 콘텐츠 제공",
                    "보유 향수 / LIKE 향수 / 시향 기록 기능 제공",
                    "서비스 개선 및 오류 대응",
                    "문의 응대 및 공지 전달"
                ]
            ),
            .init(
                title: "3. 개인정보의 보유 및 이용 기간",
                bullets: [
                    "원칙적으로 회원 탈퇴 시까지 개인정보를 보유 및 이용합니다.",
                    "사용자가 탈퇴를 요청하면 관련 법령상 보관이 필요한 경우를 제외하고 Firebase Authentication 계정과 Cloud Firestore에 저장된 사용자 데이터를 지체 없이 삭제합니다.",
                    "탈퇴 시 기기에 저장된 로컬 시향 기록도 함께 삭제합니다.",
                    "탈퇴 후 재가입 제한을 목적으로 Apple 또는 Google 계정 식별자를 별도로 보관하지 않으며, 같은 계정으로 다시 가입할 수 있습니다.",
                    "법령에 따라 일정 기간 보관이 필요한 정보는 해당 기간 동안 별도로 보관 후 파기합니다."
                ]
            ),
            .init(
                title: "4. 개인정보의 제3자 제공",
                body: "킁킁은 원칙적으로 사용자의 개인정보를 외부에 제공하지 않습니다.",
                footer: "다만, 법령에 특별한 규정이 있거나 사용자의 별도 동의가 있는 경우에는 예외로 합니다."
            ),
            .init(
                title: "5. 개인정보 처리에 사용하는 외부 서비스",
                body: "킁킁은 서비스 운영을 위해 다음 외부 서비스를 사용할 수 있습니다.",
                bullets: [
                    "Apple 로그인(Sign in with Apple): 로그인 인증 처리",
                    "Google 로그인(Google Sign-In): 로그인 인증 처리",
                    "Firebase Authentication: 사용자 인증 처리",
                    "Cloud Firestore: 사용자 데이터 저장 및 동기화",
                    "Google Gemini API: 향수 취향 분석 및 추천 생성 (입력한 취향 데이터가 Google 서버로 전송될 수 있음)",
                    "Fragella API: 향수 정보 검색 (검색어가 Fragella 서버로 전송됨)"
                ]
            ),
            .init(
                title: "6. 개인정보의 파기 절차 및 방법",
                bullets: [
                    "개인정보 보유 기간이 종료되거나 처리 목적이 달성된 경우 해당 정보를 지체 없이 삭제합니다.",
                    "전자적 파일 형태의 정보는 복구 또는 재생이 어렵도록 안전한 방식으로 삭제합니다.",
                    "출력물 등으로 존재하는 정보는 분쇄 또는 파쇄 등 적절한 방식으로 파기합니다."
                ]
            ),
            .init(
                title: "7. 이용자의 권리",
                body: "이용자는 언제든지 자신의 개인정보에 대해 열람, 정정, 삭제를 요청할 수 있습니다.",
                footer: "서비스 내에서 직접 수정 가능한 정보는 앱에서 변경할 수 있으며, 추가 문의가 필요한 경우 아래 연락처로 문의할 수 있습니다."
            ),
            .init(
                title: "8. 개인정보의 안전성 확보 조치",
                body: "킁킁은 개인정보 보호를 위해 다음과 같은 조치를 시행합니다.",
                bullets: [
                    "접근 권한의 최소화",
                    "인증 기반 접근 관리",
                    "개인정보가 저장된 서비스에 대한 보안 설정 적용",
                    "필요한 범위 내 최소 정보만 수집"
                ]
            ),
            .init(
                title: "9. 개인정보 보호 문의",
                body: "킁킁은 개인정보 처리와 관련한 이용자의 문의를 성실히 처리하고 있습니다.\n개인정보 처리와 관련한 문의사항이 있으신 경우 아래 이메일로 연락해 주시기 바랍니다.",
                email: "app.kungkung.contact@gmail.com"
            ),
            .init(
                title: "10. 고지 및 변경",
                body: "본 개인정보처리방침은 서비스 내용 또는 관련 법령 변경에 따라 수정될 수 있습니다.",
                footer: "중요한 변경이 있는 경우 앱 내 공지 또는 업데이트를 통해 안내합니다."
            )
        ]
    }

    enum TastingNoteDetailUI {
        static let deleteAlertTitle = "시향 기록 삭제"
        static let delete = "삭제"
        static let cancel = "취소"
        static let edit = "수정"
        static let ratingTitle = "향 선호도"
        static let moodTitle = "분위기&이미지"
        static let revisitTitle = "다시 쓰고 싶은지"
        static let memoTitle = "시향 메모"
        static let deleteAlertMessage = "이 시향 기록을 삭제할까요?\n삭제 후 복구할 수 없어요."

        static func title(_ perfumeName: String) -> String {
            "\(perfumeName) 시향 기록"
        }
    }

    enum TastingNoteFormUI {
        static let errorTitle = "오류"
        static let confirm = "확인"
        static let perfumeName = "향수 명"
        static let perfumePlaceholder = "향수 명을 입력해주세요"
        static let search = "검색"
        static let noSearchResult = "검색 결과가 없어요"
        static let ratingTitle = "향 선호도"
        static let moodTitle = "분위기&이미지"
        static let memoTitle = "시향 메모"
        static let memoPlaceholder = "향수에 대한 느낌을 자유롭게 기록해주세요 (최소 10자)"
        static let reset = "초기화"
        static let save = "작성 완료"
    }
}

struct PolicySectionContent {
    let title: String
    var body: String? = nil
    var bullets: [String] = []
    var footer: String? = nil
    var email: String? = nil
}
