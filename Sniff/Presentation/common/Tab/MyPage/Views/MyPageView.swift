//
//  MyPageView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
import UIKit

@MainActor
struct MyPageView: View {

    @StateObject private var viewModel: MyPageViewModel

    private enum Layout {
        static let horizontalPadding: CGFloat = 20
        static let headerTopPadding: CGFloat = 12
        static let sectionSpacing: CGFloat = 30
        static let sectionContentSpacing: CGFloat = 10
        static let sectionHeaderBottomSpacing: CGFloat = 4
        static let profileTopSpacing: CGFloat = 10
        static let profileBottomSpacing: CGFloat = 12
        static let profileImageSize: CGFloat = 84
        static let profileTextSpacing: CGFloat = 8
        static let cardSpacing: CGFloat = 18
        static let trailingPeekInset: CGFloat = PerfumeGridCardLayout.previewTrailingPeekInset
        static let likedSectionTopSpacing: CGFloat = 18
        static let bottomContentPadding: CGFloat = 68

        static var cardWidth: CGFloat {
            let availableWidth = UIScreen.main.bounds.width - (horizontalPadding * 2)
            return min(max(availableWidth * 0.48, 180), 196)
        }
    }

    init(viewModel: MyPageViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    headerSection
                    profileSection
                    ownedSection
                    likedSection
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, Layout.headerTopPadding)
                .padding(.bottom, Layout.bottomContentPadding)
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
            .onReceive(NotificationCenter.default.publisher(for: .tastingNotesDidChange)) { _ in
                Task { await viewModel.load() }
            }
            .alert(AppStrings.Profile.errorTitle, isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button(AppStrings.Profile.confirm) { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text(AppStrings.Profile.MyPage.title)
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            NavigationLink {
                SettingsSceneFactory.makeSettingsView()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
    }

    private var profileSection: some View {
        HStack(spacing: 16) {
            CheckerboardProfilePlaceholder()
                .frame(width: Layout.profileImageSize, height: Layout.profileImageSize)

            VStack(alignment: .leading, spacing: Layout.profileTextSpacing) {
                Text(viewModel.profileInfo?.nickname ?? AppStrings.Profile.userFallback)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.primary)

                Text(viewModel.profileInfo?.email ?? AppStrings.Profile.missingEmail)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(.systemGray))
                    .lineLimit(1)
            }
        }
        .padding(.top, Layout.profileTopSpacing)
        .padding(.bottom, Layout.profileBottomSpacing)
    }

    private var ownedSection: some View {
        VStack(alignment: .leading, spacing: Layout.sectionContentSpacing) {
            sectionHeader(
                title: AppStrings.Profile.MyPage.ownedTitle,
                count: viewModel.ownedCount,
                destination: TastingNoteSceneFactory.makeOwnedPerfumeListView()
            )

            if viewModel.ownedPerfumes.isEmpty {
                emptySection(
                    title: AppStrings.Profile.MyPage.emptyOwnedTitle,
                    message: AppStrings.Profile.MyPage.emptyOwnedMessage
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: Layout.cardSpacing) {
                        ForEach(viewModel.ownedPerfumes) { perfume in
                            previewNavigationCard(
                                perfume: perfume.sourcePerfume,
                                imageURL: perfume.imageURL,
                                brand: perfume.brand,
                                name: perfume.name,
                                accords: perfume.accordTags,
                                isLiked: perfume.isLiked,
                                hasTastingRecord: perfume.hasTastingRecord
                            ) {
                                Task { await viewModel.toggleOwnedPerfumeLike(id: perfume.id) }
                            }
                        }
                    }
                    .padding(.trailing, Layout.trailingPeekInset)
                }
            }
        }
    }

    private var likedSection: some View {
        VStack(alignment: .leading, spacing: Layout.sectionContentSpacing) {
            sectionHeader(
                title: AppStrings.Profile.MyPage.likedTitle,
                count: viewModel.likedCount,
                destination: TastingNoteSceneFactory.makeLikedPerfumeListView()
            )

            if viewModel.likedPerfumes.isEmpty {
                emptySection(
                    title: AppStrings.Profile.MyPage.emptyLikedTitle,
                    message: AppStrings.Profile.MyPage.emptyLikedMessage
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: Layout.cardSpacing) {
                        ForEach(viewModel.likedPerfumes) { perfume in
                            previewNavigationCard(
                                perfume: perfume.sourcePerfume,
                                imageURL: perfume.imageURL,
                                brand: perfume.brand,
                                name: perfume.name,
                                accords: perfume.accordTags,
                                isLiked: true,
                                hasTastingRecord: perfume.hasTastingRecord
                            ) {
                                Task { await viewModel.removeLikedPerfume(id: perfume.id) }
                            }
                        }
                    }
                    .padding(.trailing, Layout.trailingPeekInset)
                }
            }
        }
        .padding(.top, Layout.likedSectionTopSpacing)
    }

    private func sectionHeader<Destination: View>(
        title: String,
        count: Int,
        destination: Destination
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            Text(AppStrings.Profile.MyPage.count(count))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)

            Spacer()

            NavigationLink {
                destination
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, Layout.sectionHeaderBottomSpacing)
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
        isLiked: Bool,
        hasTastingRecord: Bool
    ) -> some View {
        PerfumeGridCardView(
            imageURL: imageURL,
            brand: brand,
            name: name,
            accords: accords,
            isLiked: isLiked,
            style: .preview,
            cardWidth: Layout.cardWidth,
            showsHeartIcon: false,
            hasTastingRecord: hasTastingRecord
        )
    }

    private func previewNavigationCard(
        perfume: Perfume,
        imageURL: String?,
        brand: String,
        name: String,
        accords: [String],
        isLiked: Bool,
        hasTastingRecord: Bool,
        heartAction: @escaping () -> Void
    ) -> some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationLink {
                PerfumeDetailContainerView(perfume: perfume)
            } label: {
                compactPreviewCard(
                    imageURL: imageURL,
                    brand: brand,
                    name: name,
                    accords: accords,
                    isLiked: isLiked,
                    hasTastingRecord: hasTastingRecord
                )
            }
            .buttonStyle(.plain)

            PerfumeCardHeartButton(isLiked: isLiked, style: .preview, action: heartAction)
                .padding(.trailing, PerfumeCardStyle.preview.likeIconInset)
                .padding(.bottom, PerfumeCardStyle.preview.likeIconInset + (PerfumeCardStyle.preview.textBlockHeight ?? 0) + PerfumeCardStyle.preview.contentTopSpacing)
        }
        .frame(width: Layout.cardWidth, alignment: .topLeading)
    }
}

private struct CheckerboardProfilePlaceholder: View {
    private let tileCount = 10

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let tileSize = size / CGFloat(tileCount)

            ZStack {
                Circle()
                    .fill(Color.white)

                VStack(spacing: 0) {
                    ForEach(0..<tileCount, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<tileCount, id: \.self) { column in
                                Rectangle()
                                    .fill((row + column).isMultiple(of: 2) ? Color(red: 0.97, green: 0.97, blue: 0.97) : Color(red: 0.92, green: 0.92, blue: 0.92))
                                    .frame(width: tileSize, height: tileSize)
                            }
                        }
                    }
                }
                .clipShape(Circle())
            }
        }
    }
}

#Preview("데이터 없음") {
    MyPageView(viewModel: .mock())
}

#Preview("데이터 있음") {
    MyPageView(viewModel: .mock())
}
