//
//  WithdrawView.swift
//  Sniff
//

import SwiftUI

// MARK: - 회원탈퇴 확인 화면

struct WithdrawView: View {

    @EnvironmentObject private var appStateManager: AppStateManager
    @StateObject private var viewModel: WithdrawViewModel
    @Environment(\.dismiss) private var dismiss

    /// 탈퇴 최종 확인 Alert 표시 여부
    @State private var showConfirmAlert: Bool = false

    init(nickname: String) {
        _viewModel = StateObject(wrappedValue: WithdrawViewModel(nickname: nickname))
    }

    var body: some View {
        VStack(spacing: 0) {
            customHeader
            Divider()

            // 스크롤 영역 (로고 + 닉네임/안내 + 유의사항 박스)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // 킁킁 로고 워드마크
                    sniffLogo

                    // 닉네임 + 안내 문구
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(viewModel.nickname)님")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)

                        Text("탈퇴하기 전 유의사항을 확인해주세요")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 32)

                    // 유의사항 박스
                    noticeBox
                        .padding(.top, 28)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 하단 고정: 구분선 + 체크박스 + 탈퇴 버튼
            bottomSection
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView().tint(.primary).scaleEffect(1.3)
                }
            }
        }
        .onChange(of: viewModel.didWithdraw) { didWithdraw in
            guard didWithdraw else { return }
            appStateManager.state = .login
        }
        // 탈퇴 최종 확인 Alert
        .alert("정말 탈퇴하시겠습니까?", isPresented: $showConfirmAlert) {
            Button("탈퇴", role: .destructive) {
                Task { await viewModel.withdrawAccount() }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("탈퇴 시 모든 데이터가 영구적으로 삭제되며\n복구할 수 없습니다.")
        }
        // 오류 Alert
        .alert("오류", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("확인") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
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

            Text("회원 탈퇴")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - 킁킁 로고

    private var sniffLogo: some View {
        Text("킁킁")
            .font(.system(size: 32, weight: .heavy))
            .foregroundColor(.primary)
            .tracking(-1)
    }

    // MARK: - 유의사항 박스

    private var noticeBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("계정 탈퇴 유의사항")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            Text("계정 탈퇴 시 서비스에 등록된 개인정보와 서비스 이용 중 작성하신 모든 글이 영구적으로 삭제되며, 다시는 복구할 수 없습니다.")
                .font(.system(size: 14))
                .foregroundColor(Color(.systemGray))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 하단 고정 섹션

    private var bottomSection: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: 12) {
                // 동의 체크박스
                Button {
                    viewModel.isAgreed.toggle()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: viewModel.isAgreed ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20))
                            .foregroundColor(viewModel.isAgreed ? Color(.systemGray) : Color(.systemGray3))

                        Text("계정 탈퇴 유의사항을 확인했습니다.")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.1), value: viewModel.isAgreed)

                // 계정 탈퇴 버튼
                Button {
                    showConfirmAlert = true
                } label: {
                    Text("계정 탈퇴")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(viewModel.isAgreed ? .primary : Color(.systemGray2))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(viewModel.isAgreed ? Color(.systemGray5) : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                }
                .disabled(!viewModel.isAgreed)
                .animation(.easeInOut(duration: 0.15), value: viewModel.isAgreed)
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    NavigationStack {
        WithdrawView(nickname: "킁킁이")
            .environmentObject(AppStateManager())
    }
}
