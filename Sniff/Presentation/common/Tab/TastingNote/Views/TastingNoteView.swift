//
//  TastingNoteView.swift
//  Sniff
//
//  Created by 이정인 on 2026.04.16.
//

// MARK: - 목록 화면 (data X / data O 상태)
import SwiftUI

struct TastingNoteView: View {

    @StateObject private var viewModel: TastingNoteViewModel

    init(viewModel: TastingNoteViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

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
                    } else if viewModel.isFilteredEmpty {
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

                if !viewModel.isDeleteMode {
                    addButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $viewModel.showFormSheet, onDismiss: {
                Task { await viewModel.reload() }
            }) {
                TastingNoteSceneFactory.makeFormView { perfumeName in
                    viewModel.showToast(perfumeName: perfumeName)
                }
            }
            .alert("시향 기록 삭제", isPresented: $viewModel.showDeleteAlert) {
                Button("삭제", role: .destructive) {
                    Task { await viewModel.confirmDelete() }
                }
                Button("취소", role: .cancel) { }
            } message: {
                Text(deleteAlertMessage)
            }
            .alert("오류", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("확인") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                Task { await viewModel.reloadFromLocal() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .tastingNotesDidChange)) { _ in
                Task { await viewModel.reloadFromLocal() }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.toastMessage)
    }

    @ViewBuilder
    private var headerView: some View {
        if viewModel.isDeleteMode {
            editHeaderView
        } else {
            normalHeaderView
        }
    }

    private var normalHeaderView: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .center) {
                Text(viewModel.perfumeScope?.title ?? "시향기")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.black)

                Spacer()

                Button("편집") {
                    guard !viewModel.isEmpty else { return }
                    viewModel.toggleDeleteMode()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(.systemGray))
                .disabled(viewModel.isEmpty)
                .opacity(viewModel.isEmpty ? 0.35 : 1)
            }

            HStack(spacing: 9) {
                filterChip(title: "전체 시향기", filter: .all)
                filterChip(title: "보유 향수", filter: .owned)
                filterChip(title: "LIKE 향수", filter: .liked)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 9)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 0.6)
        }
    }

    private var editHeaderView: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.toggleDeleteMode()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44, alignment: .leading)
            }

            Text("시향 기록 편집")
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(.black)

            Spacer()

            Button("삭제") {
                viewModel.requestDeleteSelected()
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Color(red: 0.92, green: 0.16, blue: 0.14))
            .opacity(viewModel.hasSelectedNotes ? 1 : 0.35)
            .disabled(!viewModel.hasSelectedNotes)
        }
        .padding(.leading, 20)
        .padding(.trailing, 24)
        .padding(.top, 22)
        .padding(.bottom, 18)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()

            Text(emptyTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.systemGray2))

            Text(emptyMessage)
                .font(.system(size: 16))
                .foregroundColor(Color(.systemGray2))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.bottom, 90)
    }

    private var emptyTitle: String {
        if let perfumeScope = viewModel.perfumeScope {
            return "\(PerfumePresentationSupport.displayPerfumeName(perfumeScope.perfumeName)) 시향 기록이 없어요"
        }
        switch viewModel.selectedFilter {
        case .all:    return "아직 작성한 시향기가 없어요"
        case .owned:  return "보유 향수 시향기가 없어요"
        case .liked:  return "LIKE 향수 시향기가 없어요"
        }
    }

    private var emptyMessage: String {
        if viewModel.perfumeScope != nil {
            return "+ 버튼을 눌러 이 향수의 시향 기록을 추가해 주세요"
        }
        switch viewModel.selectedFilter {
        case .all:    return "+ 버튼을 눌러 첫 시향기를 작성해 주세요"
        case .owned:  return "보유 향수에 등록된 향수의 시향기만 여기에 표시돼요"
        case .liked:  return "LIKE를 누른 향수의 시향기만 여기에 표시돼요"
        }
    }

    private var noteListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(viewModel.filteredNotes) { note in
                    if viewModel.isDeleteMode {
                        Button {
                            viewModel.toggleNoteSelection(note)
                        } label: {
                            TastingNoteEditRowView(
                                note: note,
                                isSelected: viewModel.isSelected(note)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            TastingNoteDetailView(note: note, viewModel: viewModel)
                        } label: {
                            TastingNoteTextRowView(note: note)
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()
                        .padding(.leading, viewModel.isDeleteMode ? 86 : 24)
                        .opacity(0.55)
                }

                Spacer()
                    .frame(height: viewModel.isDeleteMode ? 110 : 140)
            }
            .padding(.top, viewModel.isDeleteMode ? 0 : 10)
        }
    }

    private var addButton: some View {
        Button {
            viewModel.showFormSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .regular))

                Text("시향기 등록")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .frame(height: 52)
            .background(Color.black)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
        }
    }

    private var deleteAlertMessage: String {
        viewModel.hasSelectedNotes
        ? "선택한 시향 기록을 삭제할까요?\n삭제 후 복구할 수 없어요."
        : "이 시향 기록을 삭제할까요?\n삭제 후 복구할 수 없어요."
    }

    /// 시향기 필터 칩 버튼
    private func filterChip(title: String, filter: TastingNoteFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        return Button {
            viewModel.selectFilter(filter)
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(isSelected ? Color.black : Color(.systemBackground))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color(.systemGray), lineWidth: 1.5)
                )
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

private struct TastingNoteTextRowView: View {

    let note: TastingNote

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(PerfumePresentationSupport.displayPerfumeName(note.perfumeName))
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.black)
                .lineLimit(1)

            Text(PerfumePresentationSupport.displayBrand(note.brandName))
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(.systemGray))
                .lineLimit(1)

            Text(note.updatedAt.tastingNoteFormat)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(.systemGray3))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

private struct TastingNoteEditRowView: View {

    let note: TastingNote
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            checkbox
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(PerfumePresentationSupport.displayPerfumeName(note.perfumeName))
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.black)
                    .lineLimit(1)

                Text(PerfumePresentationSupport.displayBrand(note.brandName))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(.systemGray))
                    .lineLimit(1)

                Text(note.updatedAt.tastingNoteFormat)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(.systemGray3))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 20)
        .padding(.trailing, 24)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var checkbox: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(isSelected ? Color.black : Color(.systemGray), lineWidth: 1.5)
            .frame(width: 25, height: 25)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                }
            }
    }
}
