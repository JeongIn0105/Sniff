//
//  SettingsViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class SettingsViewModel: ObservableObject {

    @Published private(set) var nickname: String = "사용자"
    @Published private(set) var email: String?
    @Published private(set) var appVersion: String = "-"
    @Published var showLogoutAlert = false
    @Published var didLogout = false
    @Published var errorMessage: String?

    private let firestoreService: FirestoreService
    private let authService: AuthService

    init(
        firestoreService: FirestoreService? = nil,
        authService: AuthService? = nil
    ) {
        self.firestoreService = firestoreService ?? .shared
        self.authService = authService ?? .shared
        appVersion = Self.currentAppVersion()
        email = Auth.auth().currentUser?.email
    }

    func load() async {
        do {
            let user = try await firestoreService.fetchUserProfile()
            nickname = user.nickname
            email = user.email
        } catch FirestoreServiceError.invalidUserProfile {
            email = Auth.auth().currentUser?.email
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        do {
            try authService.signOut()
            didLogout = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    var privacyPolicyURL: URL? {
        let rawValue = Bundle.main.object(forInfoDictionaryKey: "PrivacyPolicyURL") as? String
        guard let rawValue else { return nil }
        return URL(string: rawValue)
    }

    private static func currentAppVersion() -> String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        return "v\(shortVersion)"
    }
}
