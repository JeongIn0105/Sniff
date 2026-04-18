//
//  AccountInfoView.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import SwiftUI

struct AccountInfoView: View {

    @StateObject private var viewModel = AccountInfoViewModel()

    var body: some View {
        List {
            Button {
                viewModel.showPlaceholder(
                    title: "이메일 변경",
                    message: "다음 단계에서 실제 이메일 변경 흐름을 연결할 예정입니다."
                )
            } label: {
                accountRow(title: "이메일 변경", value: viewModel.email)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.showPlaceholder(
                    title: "로그인 기기 관리",
                    message: "다음 단계에서 실제 로그인 기기 관리 기능을 연결할 예정입니다."
                )
            } label: {
                accountRow(title: "로그인 기기 관리")
            }
            .buttonStyle(.plain)

            Button {
                viewModel.showPlaceholder(
                    title: "회원 탈퇴",
                    message: "이번 단계에서는 회원 탈퇴 화면 구조만 우선 반영했습니다."
                )
            } label: {
                Text("회원 탈퇴")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .navigationTitle("계정 정보")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            viewModel.placeholderItem?.title ?? "안내",
            isPresented: $viewModel.showPlaceholderAlert
        ) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.placeholderItem?.message ?? "")
        }
    }

    private func accountRow(title: String, value: String? = nil) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)

            Spacer(minLength: 12)

            if let value, !value.isEmpty {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.systemGray3))
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        AccountInfoView()
    }
}
