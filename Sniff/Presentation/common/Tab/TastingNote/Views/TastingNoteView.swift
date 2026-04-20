//
//  TastingNoteView.swift
//  Sniff
//
//  Created by 이정인 on 2026.04.16.
//

// MARK: - 목록 화면 (data X / data O 상태)
import SwiftUI
import Kingfisher

struct TastingNoteView: View {

    @StateObject private var viewModel = TastingNoteViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView

                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if viewModel.isEmpty {
                        emptyStateView
                    } else {
                        noteListView
                    }
                }

                if let message = viewModel.toastMessage {
                    toastBanner(message)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 96)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                addButton
                    .padding(.trailing, 20)
                    .padding(.bottom, 24)
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $viewModel.showFormSheet) {
                TastingNoteFormView { perfumeName in
                    viewModel.showToast(perfumeName: perfumeName)
                }
            }
            .alert("시향 기록 삭제", isPresented: $viewModel.showDeleteAlert) {
                Button("삭제", role: .destructive) {
                    Task { await viewModel.confirmDelete() }
                }
                Button("취소", role: .cancel) { }
            } message: {
                Text("이 시향 기록을 삭제할까요?\n삭제 후 복구할 수 없어요.")
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
        .animation(.easeInOut(duration: 0.2), value: viewModel.toastMessage)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 타이틀 + 삭제 버튼
            HStack(alignment: .center) {
                Text("시향 기록")
                    .font(.system(size: 30, weight: .bold))

                Spacer()

                Button(viewModel.isDeleteMode ? "완료" : "삭제") {
                    guard !viewModel.isEmpty else { return }
                    viewModel.toggleDeleteMode()
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
                .disabled(viewModel.isEmpty)
                .opacity(viewModel.isEmpty ? 0.35 : 1)
            }

            // 보유 향수 / LIKE 향수 태그 버튼
            HStack(spacing: 10) {
                NavigationLink {
                    OwnedPerfumeListView()
                } label: {
                    Text("보유 향수")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(.systemGray3), lineWidth: 1))
                }

                NavigationLink {
                    LikedPerfumeListView()
                } label: {
                    Text("LIKE 향수")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(.systemGray3), lineWidth: 1))
                }

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 16)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()

            Text("등록된 시향 기록이 없어요")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.systemGray2))

            Text("+ 버튼을 눌러 시향 기록을 추가해 주세요")
                .font(.system(size: 16))
                .foregroundColor(Color(.systemGray2))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.bottom, 90)
    }

    private var noteListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.notes) { note in
                    NavigationLink {
                        TastingNoteDetailView(note: note, viewModel: viewModel)
                    } label: {
                        TastingNoteRowView(
                            note: note,
                            isDeleteMode: viewModel.isDeleteMode,
                            onDelete: { viewModel.requestDelete(note) }
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.leading, viewModel.isDeleteMode ? 96 : 88)
                }

                Spacer()
                    .frame(height: 120)
            }
        }
    }

    private var addButton: some View {
        Button {
            viewModel.showFormSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))

                Text("시향기 등록")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 26)
            .frame(height: 56)
            .background(Color.black)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
        }
    }

    private func toastBanner(_ message: String) -> some View {
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

struct TastingNoteRowView: View {

    let note: TastingNote
    let isDeleteMode: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if isDeleteMode {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.red)
                }
                .padding(.leading, 20)
            }

            perfumeThumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(note.perfumeName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(note.brandName)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    if !note.mainAccords.isEmpty {
                        Text("|")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.systemGray4))

                        ForEach(Array(note.mainAccords.prefix(2).enumerated()), id: \.offset) { _, accord in
                            HStack(spacing: 3) {
                                Circle()
                                    .frame(width: 4, height: 4)
                                    .foregroundColor(accord.accordColor)
                                Text(accord)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Text(note.createdAt.tastingNoteFormat)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.tertiaryLabel))
            }

            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.leading, isDeleteMode ? 0 : 20)
        .padding(.trailing, 20)
        .contentShape(Rectangle())
    }

    private var perfumeThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))

            if let urlString = note.perfumeImageURL,
               let url = URL(string: urlString) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(width: 56, height: 56)
    }
}
