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

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    accountCell

                    settingsList
                        .padding(.top, 54)
                }
                .padding(.horizontal, 20)
                .padding(.top, 3)
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
        .alert(AppStrings.Profile.errorTitle, isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button(AppStrings.Profile.confirm) { viewModel.clearError() }
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
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Text(AppStrings.Profile.SettingsScreen.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, -6)
        .padding(.bottom, 16)
    }

    private var accountCell: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.nickname)
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 26, alignment: .leading)

            if let email = viewModel.email, !email.isEmpty {
                Text(email)
                    .font(.system(size: 15))
                    .foregroundColor(Color(.systemGray2))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var settingsList: some View {
        VStack(spacing: 0) {
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                settingsRow(title: AppStrings.Profile.SettingsScreen.privacyPolicy)
            }
            .buttonStyle(.plain)

            separator

            settingsRow(
                title: AppStrings.Profile.SettingsScreen.appVersion,
                trailing: AppStrings.Profile.SettingsScreen.currentVersion(viewModel.appVersion),
                showsChevron: false
            )

            separator

            Button {
                viewModel.showLogoutAlert = true
            } label: {
                settingsRow(
                    title: AppStrings.Profile.SettingsScreen.logout,
                    tint: Color(red: 1, green: 0.26, blue: 0.26),
                    showsChevron: false
                )
            }
            .buttonStyle(.plain)

            separator

            NavigationLink {
                SettingsSceneFactory.makeWithdrawView(nickname: viewModel.nickname)
            } label: {
                settingsRow(
                    title: AppStrings.Profile.SettingsScreen.withdraw,
                    tint: Color(.systemGray2),
                    showsChevron: false
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 1)
    }

    private func settingsRow(
        title: String,
        trailing: String? = nil,
        tint: Color = .primary,
        showsChevron: Bool = true
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(tint)

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray2))
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .frame(height: 55)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        SettingsSceneFactory.makeSettingsView()
            .environmentObject(AppStateManager())
    }
}
