//
//  SettingsView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var appStateManager: AppStateManager
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            NavigationLink {
                AccountInfoView()
            } label: {
                settingsRow(
                    title: "계정 정보",
                    primaryValue: viewModel.nickname,
                    secondaryValue: viewModel.email
                )
            }

            Button {
                viewModel.showPrivacyPolicyAlert = true
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
        .alert("로그아웃 할까요?", isPresented: $viewModel.showLogoutAlert) {
            Button("로그아웃", role: .destructive) {
                viewModel.logout()
            }
            Button("아니요", role: .cancel) { }
        }
        .alert("개인정보처리방침", isPresented: $viewModel.showPrivacyPolicyAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("이번 단계에서는 행 구조만 먼저 연결했습니다.")
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
        title: String,
        primaryValue: String,
        secondaryValue: String?
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

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.systemGray3))
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
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppStateManager())
    }
}
