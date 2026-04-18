//
//  MyPageView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
import Kingfisher

struct MyPageView: View {

    @StateObject private var viewModel = MyPageViewModel()

    private let ownedColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let likedColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    profileSection
                    ownedSection
                    likedSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .navigationTitle("마이페이지")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .task {
                await viewModel.load()
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
    }

    private var profileSection: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundColor(Color(.systemGray4))

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.profileInfo?.nickname ?? "사용자")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)

                Text(viewModel.profileInfo?.email ?? "등록된 이메일이 없어요")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var ownedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("보유 향수 \(viewModel.ownedCount)개")
                    .font(.system(size: 20, weight: .semibold))

                Spacer()

                NavigationLink {
                    OwnedPerfumeListView()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.ownedPerfumes.isEmpty {
                emptySection(
                    title: "등록된 보유 향수가 없어요",
                    message: "향수 정보 페이지에서 보유 향수를 등록해주세요"
                )
            } else {
                LazyVGrid(columns: ownedColumns, spacing: 16) {
                    ForEach(viewModel.ownedPerfumes) { perfume in
                        previewCard(
                            imageURL: perfume.imageURL,
                            brand: perfume.brand,
                            name: perfume.name,
                            accords: perfume.accordTags
                        )
                    }
                }
            }
        }
    }

    private var likedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("LIKE 향수 \(viewModel.likedCount)개")
                    .font(.system(size: 20, weight: .semibold))

                Spacer()

                NavigationLink {
                    LikedPerfumeListView()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.likedPerfumes.isEmpty {
                emptySection(
                    title: "등록된 LIKE 향수가 없어요",
                    message: "향수 카드의 하트 아이콘을 눌러 추가해주세요"
                )
            } else {
                LazyVGrid(columns: likedColumns, spacing: 12) {
                    ForEach(viewModel.likedPerfumes) { perfume in
                        compactPreviewCard(
                            imageURL: perfume.imageURL,
                            brand: perfume.brand,
                            name: perfume.name,
                            accords: perfume.accordTags
                        )
                    }
                }
            }
        }
    }

    private func emptySection(title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(.systemGray2))

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color(.systemGray3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private func previewCard(
        imageURL: String?,
        brand: String,
        name: String,
        accords: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            perfumeImage(url: imageURL, height: 152)

            Text(brand)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text(name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)

            accordChips(accords)
        }
    }

    private func compactPreviewCard(
        imageURL: String?,
        brand: String,
        name: String,
        accords: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            perfumeImage(url: imageURL, height: 110)

            Text(brand)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)

            accordChips(accords)
        }
    }

    private func perfumeImage(url: String?, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))

            if let url, let imageURL = URL(string: url) {
                KFImage(imageURL)
                    .placeholder {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 28))
                            .foregroundColor(Color(.systemGray3))
                    }
                    .resizable()
                    .scaledToFit()
                    .padding(18)
            } else {
                Image(systemName: "shippingbox")
                    .font(.system(size: 28))
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }

    private func accordChips(_ accords: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(accords, id: \.self) { accord in
                    Text(accord)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

#Preview {
    MyPageView()
}
