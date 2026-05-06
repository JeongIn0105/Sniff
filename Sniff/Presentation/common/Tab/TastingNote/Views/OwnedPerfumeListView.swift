//
//  OwnedPerfumeListView.swift
//  Sniff
//

// MARK: - 보유 향수 전체 목록 화면
import SwiftUI

struct OwnedPerfumeListView: View {

    @StateObject private var viewModel: OwnedPerfumeListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editingPerfume: CollectedPerfume?
    private enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let columnSpacing: CGFloat = 14
        static let rowSpacing: CGFloat = 32
        static let selectionInset: CGFloat = 8
    }

    init(viewModel: OwnedPerfumeListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                headerView
                filterTabsView
                    .padding(.bottom, 14)
                listMetaView
                    .padding(.bottom, 20)

                if viewModel.isLoading && viewModel.perfumes.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.isEmpty {
                    emptyStateView
                } else {
                    perfumeGridView
                }
            }

            if let message = viewModel.toastMessage {
                toastView(message)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
        .animation(.easeInOut(duration: 0.2), value: viewModel.toastMessage)
        .sheet(item: $editingPerfume) { perfume in
            OwnedPerfumeEditSheetView(
                perfume: perfume,
                onSave: { info in
                    Task {
                        if await viewModel.updateOwnedPerfume(perfume, registrationInfo: info) {
                            editingPerfume = nil
                        }
                    }
                },
                onCancel: {
                    editingPerfume = nil
                },
                onDelete: {
                    Task {
                        if await viewModel.deleteOwnedPerfume(perfume) {
                            editingPerfume = nil
                        }
                    }
                }
            )
        }
    }

    // MARK: - 헤더

    private var headerView: some View {
        HStack(spacing: 0) {
            // 뒤로가기 버튼
            Button {
                if viewModel.isEditMode {
                    viewModel.toggleEditMode()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 44)
            }

            // 타이틀 (왼쪽 정렬)
            if viewModel.isEditMode {
                Text(AppStrings.TastingNoteUI.OwnedList.editTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            } else {
                Text(AppStrings.TastingNoteUI.OwnedList.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Spacer()

            // 편집 / 삭제 버튼
            Button(viewModel.isEditMode ? AppStrings.TastingNoteUI.OwnedList.delete : AppStrings.TastingNoteUI.OwnedList.edit) {
                if viewModel.isEditMode {
                    Task { await viewModel.deleteSelectedPerfumes() }
                } else {
                    viewModel.toggleEditMode()
                }
            }
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(viewModel.isEditMode ? Color(red: 1, green: 0.26, blue: 0.26) : Color(.systemGray))
            .disabled(viewModel.isEditMode && !viewModel.hasSelection)
            .opacity(viewModel.isEditMode && !viewModel.hasSelection ? 0.35 : 1)
        }
        .padding(.horizontal, 15)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var filterTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(OwnedPerfumeListViewModel.UsageFilter.allCases, id: \.self) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
        }
    }

    private func filterChip(_ filter: OwnedPerfumeListViewModel.UsageFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        return Button {
            viewModel.selectedFilter = filter
        } label: {
            Text(filter.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color(.systemGray))
                .padding(.horizontal, 18)
                .frame(height: 40)
                .background(isSelected ? Color.primary : Color(hex: "#F2F2F3"))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var listMetaView: some View {
        HStack {
            Text(AppStrings.TastingNoteUI.OwnedList.count(viewModel.perfumeCount))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(.systemGray2))

            Spacer()

            Menu {
                ForEach(OwnedPerfumeListViewModel.SortOrder.allCases, id: \.self) { sortOrder in
                    Button(sortOrder.title) {
                        viewModel.selectedSortOrder = sortOrder
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.selectedSortOrder.title)
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Color(.systemGray))
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    // MARK: - 빈 상태

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Text(AppStrings.TastingNoteUI.OwnedList.emptyTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.systemGray2))
            Text(AppStrings.TastingNoteUI.OwnedList.emptyMessage)
                .font(.system(size: 16))
                .foregroundColor(Color(.systemGray2))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - 그리드 목록

    private var perfumeGridView: some View {
        GeometryReader { geometry in
            let cardWidth = floor((geometry.size.width - (Layout.horizontalPadding * 2) - Layout.columnSpacing) / 2)
            let columns = [
                GridItem(.fixed(cardWidth), spacing: Layout.columnSpacing),
                GridItem(.fixed(cardWidth), spacing: Layout.columnSpacing)
            ]

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: Layout.rowSpacing) {
                    ForEach(viewModel.perfumes) { perfume in
                        if viewModel.isEditMode {
                            ownedPerfumeCard(perfume, cardWidth: cardWidth)
                                .onTapGesture {
                                    viewModel.toggleSelection(for: perfume.id)
                                }
                        } else {
                            ownedPerfumeNavigationCard(perfume, cardWidth: cardWidth)
                        }
                    }
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.bottom, 40)
            }
        }
    }

    private func ownedPerfumeCard(
        _ perfume: OwnedPerfumeListViewModel.PerfumeCardItem,
        cardWidth: CGFloat
    ) -> some View {
        ZStack(alignment: .topLeading) {
            PerfumeGridCardView(
                imageURL: perfume.imageURL,
                brand: perfume.brand,
                name: perfume.name,
                accords: perfume.accordTags,
                isLiked: perfume.isLiked,
                style: .grid,
                cardWidth: cardWidth,
                showsHeartIcon: true,
                hasTastingRecord: !viewModel.isEditMode && perfume.hasTastingRecord
            )
            .overlay(alignment: .bottomLeading) {
                statusBadge(perfume.usageStatus)
                    .padding(.leading, 10)
                    .padding(.bottom, 8)
            }

            if viewModel.isEditMode {
                SelectionCheckbox(isSelected: viewModel.selectedPerfumeIDs.contains(perfume.id))
                    .padding(.top, Layout.selectionInset)
                    .padding(.leading, Layout.selectionInset)
            }
        }
        .frame(width: cardWidth, alignment: .topLeading)
    }

    private func ownedPerfumeNavigationCard(
        _ perfume: OwnedPerfumeListViewModel.PerfumeCardItem,
        cardWidth: CGFloat
    ) -> some View {
        ZStack(alignment: .bottomTrailing) {
            PerfumeDetailPushLink(perfume: perfume.sourcePerfume) {
                PerfumeGridCardView(
                    imageURL: perfume.imageURL,
                    brand: perfume.brand,
                    name: perfume.name,
                    accords: perfume.accordTags,
                    isLiked: perfume.isLiked,
                    style: .grid,
                    cardWidth: cardWidth,
                    showsHeartIcon: false,
                    hasTastingRecord: perfume.hasTastingRecord
                )
                .overlay(alignment: .bottomLeading) {
                    statusBadge(perfume.usageStatus)
                        .padding(.leading, 10)
                        .padding(.bottom, 8)
                }
            }
            .buttonStyle(.plain)

            Button {
                guard perfume.sourceCollectedPerfume.canEditRegistrationInfo else {
                    viewModel.showEditLimitToast()
                    return
                }
                editingPerfume = perfume.sourceCollectedPerfume
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.systemGray2))
                    .frame(width: 40, height: 40)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .opacity(perfume.sourceCollectedPerfume.canEditRegistrationInfo ? 1 : 0.45)
            .padding(.trailing, 10)
            .padding(.bottom, 8)
        }
        .frame(width: cardWidth, alignment: .topLeading)
    }

    private func statusBadge(_ status: CollectedPerfumeUsageStatus?) -> some View {
        Text(status?.displayName ?? "-")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: "#8A6F55"))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Color.sniffBeige)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(hex: "#D8C5B4"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func toastView(_ message: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .frame(width: 24, height: 24)
                .foregroundColor(Color.white.opacity(0.5))

            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.18, green: 0.16, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(0.8)
    }

}

// MARK: - Preview

#Preview {
    NavigationStack {
        TastingNoteSceneFactory.makeOwnedPerfumeListView()
    }
}
