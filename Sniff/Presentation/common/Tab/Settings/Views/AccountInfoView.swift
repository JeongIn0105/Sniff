//
//  AccountInfoView.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import SwiftUI

struct AccountInfoView: View {

    @StateObject private var viewModel: AccountInfoViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AccountInfoViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 커스텀 헤더
            customHeader
            Divider()

            List {
                // 이메일 변경 → EmailChangeView
                NavigationLink {
                    SettingsSceneFactory.makeEmailChangeView()
                } label: {
                    accountRow(title: "이메일 변경")
                }

                // 회원탈퇴 → WithdrawView
                NavigationLink {
                    SettingsSceneFactory.makeWithdrawView(nickname: viewModel.nickname)
                } label: {
                    accountRow(title: "회원 탈퇴")
                }
            }
            .listStyle(.plain)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - 커스텀 헤더

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

            Text("계정 정보")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Row UI

    private func accountRow(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        SettingsSceneFactory.makeAccountInfoView()
            .environmentObject(AppStateManager())
    }
}
