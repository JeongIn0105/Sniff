//
//  OwnedPerfumeListView.swift
//  Sniff
//

// MARK: - 보유 향수 전체 목록 화면
import SwiftUI
import Kingfisher

struct OwnedPerfumeListView: View {

    @StateObject private var viewModel = OwnedPerfumeListViewModel()
    @Environment(\.dismiss) private var dismiss
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

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
        .alert("오류", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("확인") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.toastMessage)
    }

    // MARK: - 헤더

    private var headerView: some View {
        ZStack {
            Text(viewModel.isEditMode ? "보유 향수 편집" : "보유 향수 \(viewModel.perfumeCount)개")
                .font(.system(size: 20, weight: .semibold))

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
                Spacer()

                Button(viewModel.isEditMode ? "삭제" : "편집") {
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
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 20)
    }

    // MARK: - 빈 상태

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("등록된 보유 향수가 없어요")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.systemGray2))
            Text("향수 정보 페이지에서 보유 향수를 등록해주세요")
                .font(.system(size: 16))
                .foregroundColor(Color(.systemGray2))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - 그리드 목록

    private var perfumeGridView: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.perfumes) { perfume in
                    if viewModel.isEditMode {
                        ownedPerfumeCard(perfume)
                            .onTapGesture {
                                viewModel.toggleSelection(for: perfume.id)
                            }
                    } else {
                        NavigationLink {
                            PerfumeDetailContainerView(perfumeId: perfume.id)
                        } label: {
                            ownedPerfumeCard(perfume)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    private func ownedPerfumeCard(_ perfume: OwnedPerfumeListViewModel.PerfumeCardItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .bottomTrailing) {
                    perfumeImage(url: perfume.imageURL)

                    if perfume.isLiked {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(.systemGray))
                            .padding(10)
                    }
                }

                if perfume.hasTastingRecord {
                    Text("시향 기록")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(.systemGray))
                        .clipShape(Capsule())
                        .padding(10)
                }

                if viewModel.isEditMode {
                    Image(systemName: viewModel.selectedPerfumeIDs.contains(perfume.id) ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(viewModel.selectedPerfumeIDs.contains(perfume.id) ? .primary : Color(.systemGray3))
                        .padding(10)
                }
            }

            Text(perfume.brand)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text(perfume.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)

            accordChips(perfume.accordTags)
        }
    }

    private func perfumeImage(url: String?) -> some View {
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
        .frame(height: 176)
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
        OwnedPerfumeListView()
    }
}

private struct PerfumeDetailContainerView: UIViewControllerRepresentable {
    let perfumeId: String

    func makeUIViewController(context: Context) -> PerfumeDetailViewController {
        PerfumeDetailViewController(perfumeId: perfumeId)
    }

    func updateUIViewController(_ uiViewController: PerfumeDetailViewController, context: Context) {}
}
