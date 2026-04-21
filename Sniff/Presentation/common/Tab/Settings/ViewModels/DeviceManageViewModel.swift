//
//  DeviceManageViewModel.swift
//  Sniff
//

import Foundation
import Combine
import FirebaseAuth
import UIKit

// MARK: - 기기 관리 뷰모델 (로컬 기기 정보 표시)

@MainActor
final class DeviceManageViewModel: ObservableObject {

    struct DeviceItem: Identifiable {
        let id: String
        let name: String       // 기기 이름 (예: "정인의 iPhone")
        let model: String      // 기기 모델 (예: "iPhone")
        let systemInfo: String // iOS 버전 (예: "iOS 17.4")
        let lastSignedIn: Date
        let isCurrent: Bool
    }

    @Published private(set) var devices: [DeviceItem] = []
    @Published private(set) var isLoading = false
    @Published var showSignOutAlert = false
    @Published var errorMessage: String?

    // MARK: - 현재 기기 정보 로드 (Firestore 불필요)

    func load() async {
        isLoading = true
        defer { isLoading = false }

        let device = UIDevice.current
        let item = DeviceItem(
            id: device.identifierForVendor?.uuidString ?? UUID().uuidString,
            name: device.name,
            model: device.model,
            systemInfo: "iOS \(device.systemVersion)",
            lastSignedIn: Date(),
            isCurrent: true
        )
        devices = [item]
    }

    // MARK: - 현재 기기에서 로그아웃

    func signOutCurrentDevice() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() { errorMessage = nil }
}
