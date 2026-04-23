//
//  LikedPerfumeListView.swift
//  Sniff
//

// MARK: - LIKE 향수 전체 목록 화면
import SwiftUI

struct LikedPerfumeListView: View {

    @StateObject private var viewModel: LikedPerfumeListViewModel
    @Environment(\.dismiss) private var dismiss
    private enum Layout {
        static let horizontalPadding: CGFloat = PerfumeGridCardLayout.listHorizontalPadding
        static let rowSpacing: CGFloat = PerfumeGridCardLayout.listRowSpacing
        static let thumbnailSize: CGFloat = PerfumeGridCardLayout.listThumbnailSize
        static let rowVerticalPadding: CGFloat = 4
        static let contentSpacing: CGFloat = 12
        static let inlineInfoSpacing: CGFloat = 7
        static let nameToMetaSpacing: CGFloat = 6
        static let badgeTopSpacing: CGFloat = 8
        static let heartSize: CGFloat = 18
        static let heartTopPadding: CGFloat = 6
    }

    init(viewModel: LikedPerfumeListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            if viewModel.isLoading && viewModel.perfumes.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                perfumeListView
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .alert(AppStrings.TastingNoteUI.errorTitle, isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button(AppStrings.TastingNoteUI.confirm) { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - 헤더

    private var headerView: some View {
        HStack(spacing: 6) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Text(AppStrings.TastingNoteUI.LikedList.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Text(AppStrings.TastingNoteUI.LikedList.count(viewModel.perfumeCount))
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(Color(.systemGray2))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 20)
    }

    // MARK: - 빈 상태

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Text(AppStrings.TastingNoteUI.LikedList.emptyTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.systemGray2))
            Text(AppStrings.TastingNoteUI.LikedList.emptyMessage)
                .font(.system(size: 16))
                .foregroundColor(Color(.systemGray2))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - 목록

    private var perfumeListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.rowSpacing) {
                ForEach(viewModel.perfumes) { perfume in
                    perfumeNavigationRow(perfume)
                }
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, Layout.horizontalPadding)
        }
    }

    private func perfumeNavigationRow(_ perfume: LikedPerfumeListViewModel.PerfumeRowItem) -> some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink {
                PerfumeDetailContainerView(perfume: perfume.sourcePerfume)
            } label: {
                perfumeRowContent(perfume)
            }
            .buttonStyle(.plain)

            Button {
                Task { await viewModel.removeLike(id: perfume.id) }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: Layout.heartSize, weight: .semibold))
                    .foregroundColor(Color(.systemGray))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .padding(.top, Layout.heartTopPadding)
        }
    }

    private func perfumeRowContent(_ perfume: LikedPerfumeListViewModel.PerfumeRowItem) -> some View {
        HStack(alignment: .top, spacing: Layout.contentSpacing) {
            perfumeImage(url: perfume.imageURL)

            VStack(alignment: .leading, spacing: 0) {
                Text(PerfumePresentationSupport.displayPerfumeName(perfume.name))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)

                likeMetaLine(
                    brand: perfume.brand,
                    accords: perfume.accordTags
                )
                .padding(.top, Layout.nameToMetaSpacing)

                if perfume.hasTastingRecord {
                    tastingRecordBadge
                        .padding(.top, Layout.badgeTopSpacing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            Spacer(minLength: 44)
        }
        .padding(.vertical, Layout.rowVerticalPadding)
    }

    private func perfumeImage(url: String?) -> some View {
        PerfumeCardArtworkView(
            imageURL: url,
            style: .listThumbnail
        )
        .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
    }

    private var tastingRecordBadge: some View {
        Text(AppStrings.TastingNoteUI.tastingRecordBadge)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color(.systemGray))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 0.97, green: 0.95, blue: 0.92))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func likeMetaLine(brand: String, accords: [String]) -> some View {
        let displayAccords = PerfumePresentationSupport.displayAccords(Array(accords.prefix(2)))

        return HStack(spacing: Layout.inlineInfoSpacing) {
            Text(PerfumePresentationSupport.displayBrand(brand))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text("|")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(.systemGray3))

            ForEach(Array(displayAccords.enumerated()), id: \.offset) { index, accord in
                HStack(spacing: 4) {
                    Circle()
                        .fill(index == 0 ? Color(red: 0.97, green: 0.67, blue: 0.67) : Color(red: 0.73, green: 0.42, blue: 0.55))
                        .frame(width: 7, height: 7)

                    Text(accord)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(.systemGray2))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Preview

#Preview {
    TastingNoteSceneFactory.makeLikedPerfumeListView()
}
