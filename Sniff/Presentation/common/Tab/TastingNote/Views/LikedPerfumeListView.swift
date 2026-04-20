//
//  LikedPerfumeListView.swift
//  Sniff
//

// MARK: - LIKE 향수 전체 목록 화면
import SwiftUI
import Kingfisher

struct LikedPerfumeListView: View {

    @StateObject private var viewModel = LikedPerfumeListViewModel()
    @Environment(\.dismiss) private var dismiss

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
        .alert("오류", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("확인") { viewModel.clearError() }
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

            Text("LIKE 향수")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Text("\(viewModel.perfumeCount)개")
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
            Text("등록된 LIKE 향수가 없어요")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.systemGray2))
            Text("향수 카드의 하트 아이콘을 눌러 추가해주세요")
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
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.perfumes) { perfume in
                    perfumeRow(perfume)
                    Divider()
                        .padding(.leading, 96)
                }
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
        }
    }

    private func perfumeRow(_ perfume: LikedPerfumeListViewModel.PerfumeRowItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            perfumeImage(url: perfume.imageURL)

            VStack(alignment: .leading, spacing: 4) {
                Text(perfume.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                accordTextLine(brand: perfume.brand, accords: perfume.accordTags)

                if perfume.hasTastingRecord {
                    tastingRecordBadge
                        .padding(.top, 4)
                }
            }
            .padding(.top, 4)

            Spacer(minLength: 8)

            Button {
                Task { await viewModel.removeLike(id: perfume.id) }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(Color(.systemGray))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
        .padding(.vertical, 14)
    }

    private func perfumeImage(url: String?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))

            if let url, let imageURL = URL(string: url) {
                KFImage(imageURL)
                    .placeholder {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 24))
                            .foregroundColor(Color(.systemGray3))
                    }
                    .resizable()
                    .scaledToFit()
                    .padding(12)
            } else {
                Image(systemName: "shippingbox")
                    .font(.system(size: 24))
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .frame(width: 88, height: 88)
    }

    private func accordTextLine(brand: String, accords: [String]) -> some View {
        let displayAccords = Array(accords.prefix(2))

        return HStack(spacing: 4) {
            Text(brand)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(.systemGray2))
                .lineLimit(1)

            if !displayAccords.isEmpty {
                Text("|")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(.systemGray3))

                ForEach(Array(displayAccords.enumerated()), id: \.offset) { index, accord in
                    Circle()
                        .fill(index == 0 ? Color(red: 0.97, green: 0.67, blue: 0.67) : Color(.systemGray3))
                        .frame(width: 8, height: 8)

                    Text(accord)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(.systemGray2))
                        .lineLimit(1)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var tastingRecordBadge: some View {
        Text("시향 기록")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color(.systemGray))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview

#Preview {
    LikedPerfumeListView()
}
