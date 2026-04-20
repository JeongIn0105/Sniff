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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 커스텀 헤더
            customHeader
            Divider()

            // MARK: - 설정 목록
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // ─ 계정 정보 셀 (닉네임 + 이메일)
                    accountCell

                    Divider().padding(.leading, 20)

                    // ── 여기 간격 ──
                    Spacer().frame(height: 24)

                    // ─ 개인정보처리방침
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        infoRow(title: "개인정보처리방침")
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 20)

                    // ─ 앱 버전 (탭 불가)
                    versionRow

                    Divider().padding(.leading, 20)

                    // ─ 로그아웃
                    Button {
                        viewModel.showLogoutAlert = true
                    } label: {
                        HStack {
                            Text("로그아웃")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider()

                    NavigationLink {
                        WithdrawView(nickname: viewModel.nickname)
                    } label: {
                        withdrawRow
                    }
                    .buttonStyle(.plain)

                    Divider()
                }
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

    // MARK: - 커스텀 헤더 (< 환경설정)

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

    // MARK: - 계정 셀 (닉네임 + 이메일)

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
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    // MARK: - 일반 항목 행

    private func infoRow(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.systemGray3))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    // MARK: - 앱 버전 행 (탭 불가)

    private var versionRow: some View {
        HStack {
            Text("앱 버전")
                .font(.system(size: 16))
                .foregroundColor(.primary)

            Spacer()

            Text("현재 버전 \(viewModel.appVersion)")
                .font(.system(size: 14))
                .foregroundColor(Color(.systemGray2))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var withdrawRow: some View {
        HStack {
            Text("회원 탈퇴")
                .font(.system(size: 13))
                .foregroundColor(Color(.systemGray))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppStateManager())
    }
}
