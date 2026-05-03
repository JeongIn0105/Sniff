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
        static let horizontalPadding: CGFloat = 16
        static let rowSpacing: CGFloat = 12
        static let thumbnailSize: CGFloat = 72
        static let rowVerticalPadding: CGFloat = 12
        static let contentSpacing: CGFloat = 16
        static let inlineInfoSpacing: CGFloat = 6
        static let nameToMetaSpacing: CGFloat = 4
        static let badgeTopSpacing: CGFloat = 10
        static let heartSize: CGFloat = 24
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
        .onReceive(NotificationCenter.default.publisher(for: .tastingNotesDidChange)) { _ in
            Task { await viewModel.load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .perfumeCollectionDidChange)) { _ in
            Task { await viewModel.load() }
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
                    .frame(width: 36, height: 44)
            }

            Text(AppStrings.TastingNoteUI.LikedList.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)

            Text(AppStrings.TastingNoteUI.LikedList.count(viewModel.perfumeCount))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(.systemGray2))

            Spacer()
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.top, 14)
        .padding(.bottom, 10)
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
        HStack(alignment: .center, spacing: 12) {
            NavigationLink {
                PerfumeDetailContainerView(perfume: perfume.sourcePerfume)
                    .toolbar(.hidden, for: .navigationBar)
            } label: {
                perfumeRowContent(perfume)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Task { await viewModel.removeLike(id: perfume.id) }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: Layout.heartSize, weight: .semibold))
                    .foregroundColor(PerfumeHeartStyle.activeColor)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Layout.rowVerticalPadding)
    }

    private func perfumeRowContent(_ perfume: LikedPerfumeListViewModel.PerfumeRowItem) -> some View {
        // 시향 기록이 있으면 상단 정렬, 없으면 중앙 정렬
        HStack(alignment: perfume.hasTastingRecord ? .top : .center, spacing: Layout.contentSpacing) {
            perfumeImage(url: perfume.imageURL)

            VStack(alignment: .leading, spacing: 0) {
                Text(PerfumePresentationSupport.displayPerfumeName(perfume.name))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
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
        }
    }

    private func perfumeImage(url: String?) -> some View {
        PerfumeCardArtworkView(
            imageURL: url,
            style: .listThumbnail
        )
        .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.systemGray5), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var tastingRecordBadge: some View {
        Text(AppStrings.TastingNoteUI.tastingRecordBadge)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color(uiColor: UIColor(red: 0.47, green: 0.39, blue: 0.31, alpha: 1)))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color(uiColor: UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1)))
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    private func likeMetaLine(brand: String, accords: [String]) -> some View {
        let displayAccords = PerfumePresentationSupport.displayAccords(Array(accords.prefix(2)))

        return HStack(spacing: Layout.inlineInfoSpacing) {
            Text(PerfumePresentationSupport.displayBrand(brand))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text("|")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(.systemGray3))

            ForEach(Array(displayAccords.enumerated()), id: \.offset) { index, accord in
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(uiColor: ScentFamilyColor.color(for: accords[index])))
                        .frame(width: 7, height: 7)

                    Text(accord)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(.systemGray))
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
