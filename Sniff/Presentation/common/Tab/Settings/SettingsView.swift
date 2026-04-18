//
//  SettingsView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var appStateManager: AppStateManager
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            NavigationLink {
                AccountInfoView()
            } label: {
                settingsRow(
                    primaryValue: viewModel.nickname,
                    secondaryValue: viewModel.email,
                    showsChevron: false
                )
            }

            Button {
                openPrivacyPolicy()
            } label: {
                rowContainer(title: "개인정보처리방침", showsChevron: true)
            }
            .buttonStyle(.plain)

            rowContainer(
                title: "앱 버전",
                primaryValue: viewModel.appVersion,
                showsChevron: false
            )

            Button {
                viewModel.showLogoutAlert = true
            } label: {
                Text("로그아웃")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .navigationTitle("환경설정")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.didLogout) { didLogout in
            guard didLogout else { return }
            appStateManager.state = .login
        }
        .alert(AppStrings.Settings.logoutTitle, isPresented: $viewModel.showLogoutAlert) {
            Button(AppStrings.Settings.logoutConfirm, role: .destructive) {
                viewModel.logout()
            }
            Button(AppStrings.Settings.logoutCancel, role: .cancel) { }
        }
        .alert("오류", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("확인") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func settingsRow(
        primaryValue: String,
        secondaryValue: String?,
        showsChevron: Bool = true
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(primaryValue)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                if let secondaryValue, !secondaryValue.isEmpty {
                    Text(secondaryValue)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .padding(.vertical, 6)
    }

    private func rowContainer(
        title: String,
        primaryValue: String? = nil,
        showsChevron: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)

            Spacer()

            if let primaryValue, !primaryValue.isEmpty {
                Text(primaryValue)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .padding(.vertical, 8)
    }

    private func openPrivacyPolicy() {
        guard let url = viewModel.privacyPolicyURL else {
            viewModel.errorMessage = "개인정보처리방침 주소가 아직 등록되지 않았어요"
            return
        }
        openURL(url)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppStateManager())
    }
}
