//
//  MyPageView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
import Kingfisher

@MainActor
struct MyPageView: View {

    @StateObject private var viewModel: MyPageViewModel

    init(viewModel: MyPageViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // 보유 향수 미리보기: LIKE 향수와 동일한 3열
    private let ownedPreviewColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    // LIKE 향수 미리보기: 3열
    private let likedPreviewColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    headerSection
                    profileSection
                    ownedSection
                        .padding(.top, 12)
                    likedSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .toolbar(.hidden, for: .navigationBar)
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

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("마이페이지")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            NavigationLink {
                SettingsSceneFactory.makeSettingsView()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
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
                    .font(.system(size: 20, weight: .semibold))
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
            HStack(alignment: .firstTextBaseline) {
                Text("보유 향수")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.primary)

                Text("\(viewModel.ownedCount)개")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                NavigationLink {
                    TastingNoteSceneFactory.makeOwnedPerfumeListView()
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
                LazyVGrid(columns: ownedPreviewColumns, spacing: 14) {
                    ForEach(viewModel.ownedPerfumes) { perfume in
                        compactPreviewCard(
                            imageURL: perfume.imageURL,
                            brand: perfume.brand,
                            name: perfume.name,
                            accords: perfume.accordTags,
                            isLiked: perfume.isLiked
                        )
                    }
                }
            }
        }
    }

    private var likedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("LIKE 향수")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text("\(viewModel.likedCount)개")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                NavigationLink {
                    TastingNoteSceneFactory.makeLikedPerfumeListView()
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
                LazyVGrid(columns: likedPreviewColumns, spacing: 14) {
                    ForEach(viewModel.likedPerfumes) { perfume in
                        compactPreviewCard(
                            imageURL: perfume.imageURL,
                            brand: perfume.brand,
                            name: perfume.name,
                            accords: perfume.accordTags,
                            isLiked: true
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

    private func compactPreviewCard(
        imageURL: String?,
        brand: String,
        name: String,
        accords: [String],
        isLiked: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))

                    if let urlString = imageURL, let resolvedURL = URL(string: urlString) {
                        KFImage(resolvedURL)
                            .placeholder {
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(.systemGray3))
                            }
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                    } else {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 20))
                            .foregroundColor(Color(.systemGray3))
                    }
                }
                .aspectRatio(1, contentMode: .fit)

                if isLiked {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.systemGray2))
                        .padding(.trailing, 7)
                        .padding(.bottom, 7)
                }
            }

            Text(brand)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .lineSpacing(1)

            accordTextLine(Array(accords.prefix(2)))
        }
    }

    private func accordTextLine(_ accords: [String]) -> some View {
        let displayAccords = Array(accords.prefix(2))

        return HStack(spacing: 8) {
            ForEach(Array(displayAccords.enumerated()), id: \.offset) { index, accord in
                HStack(spacing: 4) {
                    Circle()
                        .fill(index == 0 ? Color(red: 0.97, green: 0.67, blue: 0.67) : Color(.systemGray3))
                        .frame(width: 8, height: 8)

                    Text(accord)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(.systemGray2))
                        .lineLimit(1)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("데이터 없음") {
    MyPageView(viewModel: .mock())
}

#Preview("데이터 있음") {
    MyPageView(viewModel: .mock())
}
