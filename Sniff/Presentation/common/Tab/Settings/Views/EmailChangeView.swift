//
//  EmailChangeView.swift
//  Sniff

import SwiftUI

// MARK: - 이메일 변경 화면

struct EmailChangeView: View {

    @StateObject private var viewModel: EmailChangeViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEmailFieldFocused: Bool

    init(viewModel: EmailChangeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 커스텀 헤더
            customHeader
            Divider()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    guidanceSection

                    // 현재 이메일 표시
                    currentEmailSection

                    // 새 이메일 입력
                    newEmailSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
            }

            // 하단 버튼
            bottomButton
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.15).ignoresSafeArea()
                    ProgressView().tint(.primary)
                }
            }
        }
        // 변경 완료 얼럿
        .alert("이메일 변경 완료", isPresented: $viewModel.showSuccessAlert) {
            Button("확인", role: .cancel) { dismiss() }
        } message: {
            Text("앱에서 연락받을 이메일이 변경되었습니다.")
        }
        // 오류 얼럿
        .alert("오류", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("확인") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onTapGesture { isEmailFieldFocused = false }
        .task {
            await viewModel.loadCurrentEmail()
        }
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

            Text("이메일 변경")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - 안내 문구

    private var guidanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("로그인 계정은 Apple 로그인으로 유지됩니다.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            Text("새 이메일 주소를 입력하면 앱에서 연락받을 이메일로 사용할 수 있습니다.")
                .font(.system(size: 14))
                .foregroundColor(Color(.systemGray))
                .lineSpacing(3)
        }
    }

    // MARK: - 현재 이메일

    private var currentEmailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("현재 연락 이메일")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.systemGray))

            Text(viewModel.currentEmail)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - 새 이메일 입력

    private var newEmailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("새 연락 이메일")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.systemGray))

            TextField("앱에서 연락받을 이메일 주소를 입력해주세요", text: $viewModel.newEmail)
                .font(.system(size: 16))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .focused($isEmailFieldFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isEmailFieldFocused ? Color(.systemGray2) : Color.clear,
                            lineWidth: 1
                        )
                )

            Text("입력하신 이메일로 앱 공지 및 알림을 받게 됩니다.")
                .font(.system(size: 12))
                .foregroundColor(Color(.systemGray2))
                .lineSpacing(3)
        }
    }

    // MARK: - 하단 버튼

    private var bottomButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                isEmailFieldFocused = false
                Task { await viewModel.saveContactEmail() }
            } label: {
                Text("이메일 변경")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background((viewModel.isEmailValid && !viewModel.isLoading) ? Color.black : Color(.systemGray4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
            }
            .disabled(!viewModel.isEmailValid || viewModel.isLoading)
            .animation(.easeInOut(duration: 0.15), value: viewModel.isEmailValid)
            .animation(.easeInOut(duration: 0.15), value: viewModel.isLoading)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsSceneFactory.makeEmailChangeView()
    }
}
