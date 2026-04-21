//
//  DeviceManageView.swift
//  Sniff
//

import SwiftUI

// MARK: - 로그인 기기 관리 화면

struct DeviceManageView: View {

    @EnvironmentObject private var appStateManager: AppStateManager
    @StateObject private var viewModel: DeviceManageViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: DeviceManageViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy.MM.dd HH:mm"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            customHeader
            Divider()

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                List {
                    ForEach(viewModel.devices) { device in
                        deviceRow(device)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await viewModel.load() }
        // 로그아웃 확인 얼럿
        .alert(AppStrings.Settings.logoutTitle, isPresented: $viewModel.showSignOutAlert) {
            Button(AppStrings.Settings.logoutConfirm, role: .destructive) {
                viewModel.signOutCurrentDevice()
                appStateManager.state = .login
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

            Text("로그인 기기 관리")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - 기기 행

    private func deviceRow(_ device: DeviceManageViewModel.DeviceItem) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "iphone")
                .font(.system(size: 28))
                .foregroundColor(Color(.systemGray2))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(device.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("현재 기기")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray2))
                        .clipShape(Capsule())
                }

                Text(device.model + " · " + device.systemInfo)
                    .font(.system(size: 13))
                    .foregroundColor(Color(.systemGray))

                Text("마지막 접속: \(Self.dateFormatter.string(from: device.lastSignedIn))")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.systemGray3))
            }

            Spacer(minLength: 8)

            Button {
                viewModel.showSignOutAlert = true
            } label: {
                Text("로그아웃")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemRed).opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
    }
}

#Preview {
    NavigationStack {
        SettingsSceneFactory.makeDeviceManageView()
            .environmentObject(AppStateManager())
    }
}
