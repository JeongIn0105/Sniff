//
//  AccountInfoViewModel.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AccountInfoViewModel: ObservableObject {

    struct NoticeItem {
        let title: String
        let message: String
    }

    @Published private(set) var email: String?
    @Published private(set) var noticeItem: NoticeItem?
    @Published var showNoticeAlert = false

    init() {
        email = Auth.auth().currentUser?.email
    }

    func showNotice(title: String, message: String) {
        email = Auth.auth().currentUser?.email
        noticeItem = NoticeItem(title: title, message: message)
        showNoticeAlert = true
    }
}
