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
                viewModel.showNotice(
                    title: "이메일 변경",
                    message: "이메일 변경 기능은 다음 단계에서 연결할 예정입니다."
                )
            } label: {
                accountRow(title: "이메일 변경", value: viewModel.email, showsChevron: false)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.showNotice(
                    title: "로그인 기기 관리",
                    message: "로그인 기기 관리 기능은 다음 단계에서 연결할 예정입니다."
                )
            } label: {
                accountRow(title: "로그인 기기 관리", showsChevron: false)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.showNotice(
                    title: "회원 탈퇴",
                    message: "회원 탈퇴는 Firestore 데이터 삭제 후 Auth 삭제 순서로 다음 단계에서 연결할 예정입니다."
                )
            } label: {
                accountRow(title: "회원 탈퇴", showsChevron: false, accentColor: .red)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .navigationTitle("계정 정보")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            viewModel.noticeItem?.title ?? "안내",
            isPresented: $viewModel.showNoticeAlert
        ) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.noticeItem?.message ?? "")
        }
    }

    private func accountRow(
        title: String,
        value: String? = nil,
        showsChevron: Bool = true,
        accentColor: Color = .primary
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(accentColor)

            Spacer(minLength: 12)

            if let value, !value.isEmpty {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        AccountInfoView()
    }
}
