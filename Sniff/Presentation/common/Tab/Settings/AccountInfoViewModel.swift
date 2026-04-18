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

    struct PlaceholderItem {
        let title: String
        let message: String
    }

    @Published private(set) var email: String?
    @Published private(set) var placeholderItem: PlaceholderItem?
    @Published var showPlaceholderAlert = false

    init() {
        email = Auth.auth().currentUser?.email
    }

    func showPlaceholder(title: String, message: String) {
        placeholderItem = PlaceholderItem(title: title, message: message)
        showPlaceholderAlert = true
    }
}
