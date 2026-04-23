//
//  SettingsView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var appStateManager: AppStateManager
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            customHeader
            Divider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    settingsSection {
                        accountCell
                    }

                    settingsSection {
                        NavigationLink {
                            PrivacyPolicyView()
                        } label: {
                            settingsRow(title: "개인정보처리방침")
                        }
                        .buttonStyle(.plain)

                        settingsRow(
                            title: "앱 버전",
                            trailing: "현재 버전 \(viewModel.appVersion)",
                            showsChevron: false
                        )

                        Button {
                            viewModel.showLogoutAlert = true
                        } label: {
                            settingsRow(title: "로그아웃", tint: .red, showsChevron: false)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SettingsSceneFactory.makeWithdrawView(nickname: viewModel.nickname)
                        } label: {
                            settingsRow(title: "회원 탈퇴", tint: Color(.systemGray), showsChevron: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await viewModel.load() }
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

    private var customHeader: some View {
        HStack(spacing: 4) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Text("환경설정")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var accountCell: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.nickname)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                if let email = viewModel.email, !email.isEmpty {
                    Text(email)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
    }

    private func settingsSection<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func settingsRow(
        title: String,
        trailing: String? = nil,
        tint: Color = .primary,
        showsChevron: Bool = true
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(tint)

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray2))
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        SettingsSceneFactory.makeSettingsView()
            .environmentObject(AppStateManager())
    }
}
