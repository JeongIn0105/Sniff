//
//  AppStrings+TastingNoteUI.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum TastingNoteUI {
        static let errorTitle = "오류"
        static let confirm = "확인"
        static let tastingRecordBadge = "시향 기록"

        enum LikedList {
            static let title = "LIKE 향수"
            static let emptyTitle = "등록된 LIKE 향수가 없어요"
            static let emptyMessage = "향수 카드의 하트 아이콘을 눌러 추가해주세요"

            static func count(_ count: Int) -> String {
                "\(count)개"
            }
        }

        enum OwnedList {
            static let title = "보유 향수"
            static let editTitle = "보유 향수 편집"
            static let edit = "편집"
            static let delete = "삭제"
            static let emptyTitle = "등록된 보유 향수가 없어요"
            static let emptyMessage = "향수 정보 페이지에서 보유 향수를 등록해주세요"

            static func count(_ count: Int) -> String {
                "\(count)개"
            }
        }

        enum List {
            static let defaultTitle = "시향기"
            static let done = "완료"
            static let delete = "삭제"
            static let add = "시향기 등록"
            static let edit = "시향기 수정"
            static let deleteAlertTitle = "시향 기록 삭제"
            static let deleteAlertMessage = "이 시향 기록을 삭제할까요?\n삭제 후 복구할 수 없어요."
            static let filterAll = "전체 시향기"
            static let filterOwned = "보유 향수"
            static let filterLiked = "좋아요 향수"

            static let emptyAllTitle = "아직 작성한 시향기가 없어요"
            static let emptyOwnedTitle = "보유 향수 시향기가 없어요"
            static let emptyLikedTitle = "좋아요 향수 시향기가 없어요"
            static let scopeEmptyMessage = "+ 버튼을 눌러 이 향수의 시향 기록을 추가해 주세요"
            static let emptyAllMessage = "+ 버튼을 눌러 첫 시향기를 작성해 주세요"
            static let emptyOwnedMessage = "보유 향수에 등록된 향수의 시향기만 여기에 표시돼요"
            static let emptyLikedMessage = "좋아요를 누른 향수의 시향기만 여기에 표시돼요"

            static func scopeEmptyTitle(_ perfumeName: String) -> String {
                "\(perfumeName) 시향기가 없어요"
            }
        }
    }
}
