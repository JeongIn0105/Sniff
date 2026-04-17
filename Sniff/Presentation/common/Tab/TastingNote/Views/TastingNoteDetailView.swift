//
//  TastingNoteDetailView.swift
//  Sniff
//
//  Created by 이정인 on 4/16/26.
//

// MARK: - 상세 화면 (새로 추가)
import SwiftUI
import Kingfisher

struct TastingNoteDetailView: View {

    let note: TastingNote
    @ObservedObject var viewModel: TastingNoteViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert: Bool = false
    @State private var showEditSheet: Bool = false

    private var currentNote: TastingNote {
        guard let id = note.id,
              let liveNote = viewModel.notes.first(where: { $0.id == id }) else {
            return note
        }
        return liveNote
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    headerView

                    perfumeInfoCard
                        .padding(.horizontal, 20)

                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)

                    ratingDisplaySection(
                        title: "향 선호도",
                        rating: currentNote.rating,
                        label: currentNote.rating.ratingLabel
                    )
                    .padding(.horizontal, 20)

                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)

                    moodTagDisplaySection
                        .padding(.horizontal, 20)

                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)

                    if let desire = currentNote.revisitDesire {
                        revisitDesireDisplaySection(desire)
                            .padding(.horizontal, 20)

                        Divider()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                    }

                    memoDisplaySection
                        .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showEditSheet) {
            TastingNoteFormView(editingNote: currentNote)
        }
        .alert("시향 기록 삭제", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                Task {
                    await viewModel.deleteNote(currentNote)
                    dismiss()
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("이 시향 기록을 삭제할까요?\n삭제 후 복구할 수 없어요.")
        }
    }

    private var headerView: some View {
        ZStack {
            Text("\(currentNote.perfumeName) 시향 기록")
                .font(.system(size: 17, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 72)

            HStack {
                // 뒤로 가기 버튼 (동그라미 없음)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                // 수정/삭제 메뉴 (동그라미 없음)
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("수정", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 20)
    }

    private var perfumeInfoCard: some View {
        HStack(spacing: 14) {
            Group {
                if let urlString = currentNote.perfumeImageURL,
                   let url = URL(string: urlString) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                }
            }
            .frame(width: 110, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text(currentNote.brandName)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                Text(currentNote.perfumeName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                if !currentNote.mainAccords.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(currentNote.mainAccords.prefix(3), id: \.self) { accord in
                            HStack(spacing: 4) {
                                Circle()
                                    .frame(width: 5, height: 5)
                                    .foregroundColor(accord.accordColor)

                                Text(accord)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Spacer()
        }
    }

    private func ratingDisplaySection(title: String, rating: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))

            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: 30))
                        .foregroundColor(star <= rating ? .primary : Color(.systemGray4))
                }

                Text("\(rating)")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.leading, 4)

                Text("/5")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }

    private var moodTagDisplaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("분위기&이미지")
                .font(.system(size: 17, weight: .semibold))

            ChipFlowLayout(spacing: 8) {
                ForEach(currentNote.moodTags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func revisitDesireDisplaySection(_ desire: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("다시 쓰고 싶은지")
                .font(.system(size: 17, weight: .semibold))

            Text(desire)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black)
                .clipShape(Capsule())
        }
    }

    private var memoDisplaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("시향 메모")
                .font(.system(size: 17, weight: .semibold))

            ZStack(alignment: .bottomTrailing) {
                Text(currentNote.memo)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                    .padding(14)

                Text("\(currentNote.memo.count)/2000")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 12)
                    .padding(.bottom, 10)
            }
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

