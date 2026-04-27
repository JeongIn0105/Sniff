//
//  OwnedPerfumeListView.swift
//  Sniff
//

// MARK: - 보유 향수 전체 목록 화면
import SwiftUI

struct OwnedPerfumeListView: View {

    @StateObject private var viewModel: OwnedPerfumeListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showsMonthlyUsageInfo = false
    private enum Layout {
        static let horizontalPadding: CGFloat = PerfumeGridCardLayout.gridHorizontalPadding
        static let columnSpacing: CGFloat = PerfumeGridCardLayout.gridColumnSpacing
        static let rowSpacing: CGFloat = PerfumeGridCardLayout.gridRowSpacing
        static let selectionInset: CGFloat = 5
    }

    init(viewModel: OwnedPerfumeListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                headerView

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
                    .frame(width: 44, height: 44)
            }

            // 타이틀 (왼쪽 정렬)
            if viewModel.isEditMode {
                Text(AppStrings.TastingNoteUI.OwnedList.editTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
            } else {
                HStack(spacing: 6) {
                    Text(AppStrings.TastingNoteUI.OwnedList.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text(AppStrings.TastingNoteUI.OwnedList.count(viewModel.perfumeCount))
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(.systemGray2))

                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            showsMonthlyUsageInfo.toggle()
                        }
                    } label: {
                        ZStack {
                            if showsMonthlyUsageInfo {
                                Text(AppStrings.CollectionUsageLimits.monthlyUsage(
                                    viewModel.monthlyUsageCount,
                                    limit: viewModel.monthlyUsageLimit
                                ))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(.systemGray))
                                .padding(.horizontal, 9)
                                .frame(height: 26)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            } else {
                                Text("!")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color(.systemGray))
                                    .frame(width: 22, height: 22)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
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
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(viewModel.isEditMode ? .red : .primary)
            .disabled(viewModel.isEditMode && !viewModel.hasSelection)
            .opacity(viewModel.isEditMode && !viewModel.hasSelection ? 0.35 : 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 20)
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

            if viewModel.isEditMode {
                Image(systemName: viewModel.selectedPerfumeIDs.contains(perfume.id) ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(viewModel.selectedPerfumeIDs.contains(perfume.id) ? Color(.systemGray) : Color(.systemGray3))
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
            NavigationLink {
                PerfumeDetailContainerView(perfume: perfume.sourcePerfume)
            } label: {
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
            }
            .buttonStyle(.plain)

            PerfumeCardHeartButton(isLiked: perfume.isLiked, style: .grid) {
                Task { await viewModel.toggleLike(for: perfume.id) }
            }
            .padding(.trailing, PerfumeCardStyle.grid.likeIconInset)
            .padding(.bottom, PerfumeCardStyle.grid.likeIconInset + (PerfumeCardStyle.grid.textBlockHeight ?? 0) + PerfumeCardStyle.grid.contentTopSpacing)
        }
        .frame(width: cardWidth, alignment: .topLeading)
    }

    private func toastView(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TastingNoteSceneFactory.makeOwnedPerfumeListView()
    }
}
