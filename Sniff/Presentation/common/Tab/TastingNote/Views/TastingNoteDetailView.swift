//
//  TastingNoteDetailView.swift
//  Sniff
//
//  Created by 이정인 on 4/16/26.
//

// MARK: - 시향기 상세 화면
import SwiftUI
import Kingfisher

struct TastingNoteDetailView: View {

    let note: TastingNote
    @ObservedObject var viewModel: TastingNoteViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet: Bool = false

    // 목록 viewModel의 notes를 구독해 실시간으로 최신 데이터 반영
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

                    // 시향 향수 섹션 (헤더 아래 12pt 여백)
                    perfumeInfoSection
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)

                    detailSectionDivider

                    // 향 선호도 섹션
                    ratingSection
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 0)

                    // 분위기&이미지 섹션 (구분선 없음, 40pt 상단 여백)
                    moodTagSection
                        .padding(.horizontal, 16)
                        .padding(.top, 40)
                        .padding(.bottom, 0)

                    // 시향 메모 섹션 (구분선 없음, 40pt 상단 여백)
                    memoSection
                        .padding(.horizontal, 16)
                        .padding(.top, 40)
                        .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showEditSheet) {
            TastingNoteSceneFactory.makeFormView(editingNote: currentNote)
        }
    }

    // MARK: - 헤더 (와이어프레임: 좌측 정렬 chevron + 제목, 우측 "편집" 버튼)

    private var headerView: some View {
        HStack(spacing: 0) {
            // 뒤로 가기 버튼
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            // 향수 이름 제목 (좌측 정렬)
            Text(PerfumePresentationSupport.displayPerfumeName(currentNote.perfumeName))
                .font(.custom("Pretendard", size: 20).weight(.medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            // 편집 버튼 (와이어프레임: 우측에 "편집" 텍스트 버튼)
            Button("편집") {
                showEditSheet = true
            }
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(.primary)
            .padding(.trailing, 16)
        }
        .padding(.leading, 4)
        .frame(height: 52)
        .padding(.bottom, 8)
    }

    // MARK: - 시향 향수 섹션 (와이어프레임: 이름 bold, 브랜드, 마지막 작성일)

    private var perfumeInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 섹션 레이블
            Text("시향 향수")
                .font(.custom("Pretendard", size: 17).weight(.semibold))
                .foregroundColor(.primary)

            // 향수 이름 (bold)
            HStack(alignment: .top, spacing: 12) {
                perfumeImageView

                VStack(alignment: .leading, spacing: 0) {
                    Text(PerfumePresentationSupport.displayPerfumeName(currentNote.perfumeName))
                        .font(.custom("Pretendard", size: 20).weight(.bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    // 브랜드
                    Text(PerfumePresentationSupport.displayBrand(currentNote.brandName))
                        .font(.custom("Pretendard", size: 15).weight(.regular))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    if !currentNote.mainAccords.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(PerfumePresentationSupport.displayAccords(Array(currentNote.mainAccords.prefix(3))), id: \.self) { accord in
                                accordChip(accord)
                            }
                        }
                        .padding(.top, 12)
                    }
                }
            }
            .padding(.top, 16)


            // 마지막 작성일
            Text("마지막 작성일: \(currentNote.updatedAt.tastingNoteFormat)")
                .font(.custom("Pretendard", size: 13).weight(.regular))
                .foregroundColor(Color(.systemGray3))
                .padding(.top, 24)
        }
    }

    @ViewBuilder
    private var perfumeImageView: some View {
        if let urlString = currentNote.perfumeImageURL,
           let url = URL(string: urlString) {
            KFImage(url)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func accordChip(_ accord: String) -> some View {
        Text(accord)
            .font(.custom("Pretendard", size: 13).weight(.regular))
            .foregroundColor(accord.accordColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accord.accordBackgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(accord.accordBorderColor, lineWidth: 1)
            )
    }

    private var detailSectionDivider: some View {
        Rectangle()
            .fill(Color(.systemGray6))
            .frame(maxWidth: .infinity)
            .frame(height: 8)
    }

    // MARK: - 향 선호도 섹션 (와이어프레임: "향 선호도 | 보통" 인라인 라벨)

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 제목과 라벨 인라인 표시
            HStack(spacing: 6) {
                Text("향 선호도")
                    .font(.custom("Pretendard", size: 17).weight(.semibold))
                    .foregroundColor(.primary)

                if currentNote.rating > 0 {
                    Text("|")
                        .font(.custom("Pretendard", size: 17).weight(.regular))
                        .foregroundColor(Color(.systemGray3))

                    Text(currentNote.rating.ratingLabel)
                        .font(.custom("Pretendard", size: 17).weight(.regular))
                        .foregroundColor(.secondary)
                }
            }

            // 별점 표시
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= currentNote.rating ? "star.fill" : "star")
                        .font(.system(size: 28))
                        .foregroundColor(star <= currentNote.rating ? .primary : Color(.systemGray4))
                }

                Text("\(currentNote.rating)")
                    .font(.custom("Pretendard", size: 17).weight(.semibold))
                    .foregroundColor(.primary)
                    .padding(.leading, 4)

                Text("/5")
                    .font(.custom("Pretendard", size: 14).weight(.regular))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - 분위기&이미지 섹션 (와이어프레임: 아웃라인 칩 스타일)

    private var moodTagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("분위기&이미지")
                .font(.custom("Pretendard", size: 17).weight(.semibold))
                .foregroundColor(.primary)

            // 아웃라인 스타일 칩 (와이어프레임: 검정 테두리, 흰 배경, 검정 텍스트)
            ChipFlowLayout(spacing: 8) {
                ForEach(currentNote.moodTags, id: \.self) { tag in
                    Text(tag)
                        .font(.custom("Pretendard", size: 13).weight(.regular))
                        .foregroundColor(Color(.label))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(Color(.systemBackground))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color(.label), lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - 시향 메모 섹션 (와이어프레임: 글자 수 카운터 없음)

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("시향 메모")
                .font(.custom("Pretendard", size: 17).weight(.semibold))
                .foregroundColor(.primary)

            Text(currentNote.memo)
                .font(.custom("Pretendard", size: 15).weight(.regular))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .lineSpacing(4)
        }
    }
}
