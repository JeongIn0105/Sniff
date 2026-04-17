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

    var body: some View {
        VStack(spacing: 0) {
            headerView

            if viewModel.isLoading {
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
        ZStack {
            Text("보유 향수")
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
            Text("향수를 추가해 보유 향수를 관리해 보세요")
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
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.perfumes, id: \.id) { perfume in
                    PerfumeRowView(
                        name: perfume.name,
                        brand: perfume.brand,
                        scentFamilies: perfume.scentFamilies,
                        imageURL: perfume.imageURL,
                        date: perfume.createdAt
                    )
                    Divider()
                        .padding(.leading, 88)
                }
                Spacer().frame(height: 40)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OwnedPerfumeListView()
}
