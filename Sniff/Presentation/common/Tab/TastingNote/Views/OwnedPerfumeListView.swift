//
//  OwnedPerfumeListView.swift
//  Sniff
//

// MARK: - 보유 향수 전체 목록 화면
import SwiftUI
import Kingfisher

struct OwnedPerfumeListView: View {

    @StateObject private var viewModel: OwnedPerfumeListViewModel
    @Environment(\.dismiss) private var dismiss
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

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
                Text("보유 향수 편집")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
            } else {
                HStack(spacing: 6) {
                    Text("보유 향수")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text("\(viewModel.perfumeCount)개")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(.systemGray2))
                }
            }

            Spacer()

            // 편집 / 삭제 버튼
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
                            TastingNoteSceneFactory.makeListView(
                                perfumeScope: TastingNotePerfumeScope(
                                    perfumeName: perfume.name,
                                    brandName: perfume.brand
                                )
                            )
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
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .bottomTrailing) {
                    perfumeImage(url: perfume.imageURL)

                    if perfume.isLiked {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(.systemGray2))
                            .padding(.trailing, 10)
                            .padding(.bottom, 10)
                    }
                }

                if perfume.hasTastingRecord && !viewModel.isEditMode {
                    tastingRecordBadge
                        .padding(.top, 0)
                        .padding(.leading, 0)
                }

                if viewModel.isEditMode {
                    Image(systemName: viewModel.selectedPerfumeIDs.contains(perfume.id) ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(viewModel.selectedPerfumeIDs.contains(perfume.id) ? Color(.systemGray) : Color(.systemGray3))
                        .padding(.top, 8)
                        .padding(.leading, 8)
                }
            }

            Text(perfume.brand)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text(perfume.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .lineSpacing(2)
                .lineLimit(2)

            accordTextLine(perfume.accordTags)
        }
    }

    private var tastingRecordBadge: some View {
        Text("시향 기록")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.leading, 12)
            .padding(.trailing, 18)
            .padding(.vertical, 7)
            .background(Color(.systemGray))
            .clipShape(AttachedOwnedTastingRecordBadgeShape())
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

private struct AttachedOwnedTastingRecordBadgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.height / 2

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.midY),
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TastingNoteSceneFactory.makeOwnedPerfumeListView()
    }
}

private struct PerfumeDetailContainerView: UIViewControllerRepresentable {
    let perfumeId: String

    func makeUIViewController(context: Context) -> PerfumeDetailViewController {
        PerfumeDetailSceneFactory.makeViewController(perfumeId: perfumeId)
    }

    func updateUIViewController(_ uiViewController: PerfumeDetailViewController, context: Context) {}
}
