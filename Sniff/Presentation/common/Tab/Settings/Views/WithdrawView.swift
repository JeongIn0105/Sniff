//
//  WithdrawView.swift
//  Sniff
//

import SwiftUI
import CoreText

// MARK: - 회원탈퇴 확인 화면

struct WithdrawView: View {

    @EnvironmentObject private var appStateManager: AppStateManager
    @StateObject private var viewModel: WithdrawViewModel
    @Environment(\.dismiss) private var dismiss

    /// 탈퇴 최종 확인 Alert 표시 여부
    @State private var showConfirmAlert: Bool = false

    init(viewModel: WithdrawViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            customHeader

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    sniffLogo

                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppStrings.Profile.Withdraw.nickname(viewModel.nickname))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(minHeight: 22, alignment: .leading)

                        Text(AppStrings.Profile.Withdraw.guide)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(minHeight: 22, alignment: .leading)
                    }
                    .padding(.top, 16)

                    noticeBox
                        .padding(.top, 22)

                    agreementRow
                        .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

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
        .alert(AppStrings.Profile.Withdraw.confirmTitle, isPresented: $showConfirmAlert) {
            Button(AppStrings.Profile.Withdraw.confirmDestructive, role: .destructive) {
                Task { await viewModel.withdrawAccount() }
            }
            Button(AppStrings.Profile.Withdraw.cancel, role: .cancel) { }
        } message: {
            Text(AppStrings.Profile.Withdraw.confirmMessage)
        }
        // 오류 Alert
        .alert(AppStrings.Profile.errorTitle, isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button(AppStrings.Profile.confirm) { viewModel.clearError() }
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

            Text(AppStrings.Profile.Withdraw.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, -6)
        .padding(.bottom, 14)
    }

    // MARK: - 킁킁 로고

    private var sniffLogo: some View {
        HahmletLogoText(text: AppStrings.Profile.Withdraw.appName)
            .frame(width: 47, height: 37, alignment: .leading)
    }

    // MARK: - 유의사항 박스

    private var noticeBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppStrings.Profile.Withdraw.noticeTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            Text(AppStrings.Profile.Withdraw.noticeBody)
                .font(.system(size: 14))
                .foregroundColor(Color(.systemGray))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.98, green: 0.96, blue: 0.94))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 하단 고정 섹션

    private var bottomSection: some View {
        VStack(spacing: 0) {
            Button {
                showConfirmAlert = true
            } label: {
                Text(AppStrings.Profile.Withdraw.action)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(viewModel.isAgreed ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(!viewModel.isAgreed)
            .animation(.easeInOut(duration: 0.15), value: viewModel.isAgreed)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(Color(.systemBackground))
    }

    private var agreementRow: some View {
        Button {
            viewModel.isAgreed.toggle()
        } label: {
            HStack(spacing: 8) {
                checkbox

                Text(AppStrings.Profile.Withdraw.agreement)
                    .font(.custom("Pretendard", size: 15).weight(.medium))
                    .foregroundColor(viewModel.isAgreed ? Color(red: 0.3, green: 0.3, blue: 0.3) : Color(red: 0.5, green: 0.5, blue: 0.5))

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.1), value: viewModel.isAgreed)
    }

    private var checkbox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(viewModel.isAgreed ? Color.black : Color.white)

            RoundedRectangle(cornerRadius: 4)
                .stroke(viewModel.isAgreed ? Color.black : Color(red: 0.7, green: 0.7, blue: 0.7), lineWidth: 1)

            if viewModel.isAgreed {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 24, height: 24)
    }
}

private struct HahmletLogoText: UIViewRepresentable {

    let text: String

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 1
        label.lineBreakMode = .byClipping
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        HahmletFontLoader.registerIfNeeded()

        let font = HahmletFontLoader.logoFont(size: 24)
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .kern: 2,
                .foregroundColor: UIColor.black
            ]
        )
    }
}

private enum HahmletFontLoader {

    private static var didRegister = false

    static func registerIfNeeded() {
        guard !didRegister else { return }
        didRegister = true

        [
            ("Hahmlet-Bold", "ttf"),
            ("Hahmlet-Bold", "otf"),
            ("Hahmlet", "ttf"),
            ("Hahmlet", "otf"),
            ("Hahmlet-VariableFont_wght", "ttf")
        ].forEach { name, ext in
            guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func logoFont(size: CGFloat) -> UIFont {
        if let font = UIFont(name: "Hahmlet-Bold", size: size) {
            return font
        }

        if let font = UIFont(name: "Hahmlet", size: size) {
            return font
        }

        return .systemFont(ofSize: size, weight: .bold)
    }
}

#Preview {
    NavigationStack {
        WithdrawView(viewModel: WithdrawViewModel(
            nickname: "킁킁이",
            authService: AuthService.shared,
            coreDataStack: .shared
        ))
            .environmentObject(AppStateManager())
    }
}
