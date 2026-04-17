//
//  TastingNoteFormView.swift
//  Sniff
//
//  Created by 이정인 on 4/16/26.
//

// MARK: - 등록 / 수정 화면
import SwiftUI
import Kingfisher

struct TastingNoteFormView: View {

    @StateObject private var vm: TastingNoteFormViewModel
    @Environment(\.dismiss) private var dismiss
    private let onSaveSuccess: (String) -> Void

    init(
        editingNote: TastingNote? = nil,
        onSaveSuccess: @escaping (String) -> Void = { _ in }
    ) {
        _vm = StateObject(wrappedValue: TastingNoteFormViewModel(editingNote: editingNote))
        self.onSaveSuccess = onSaveSuccess
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                ScrollView(showsIndicators: false) {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading, spacing: 32) {
                            searchSection
                                .zIndex(10)
                                .id("formTop")

                            if let fragrance = vm.displayCardFragrance {
                                selectedCard(fragrance)
                            }

                            ratingSection(title: "향 선호도",   value: $vm.rating,    label: vm.rating.ratingLabel)
                            moodTagSection
                            memoSection
                            Spacer().frame(height: 24)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                        // 향수 선택 시 상단으로 스크롤
                        .onChange(of: vm.selectedFragrance?.id) { _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("formTop", anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) { bottomBar }
        .onChange(of: vm.saveSuccess) { success in
            if success { onSaveSuccess(vm.savedPerfumeName); dismiss() }
        }
        .alert("오류", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("확인") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - 헤더

    private var headerView: some View {
        ZStack {
            Text(vm.navigationTitle)
                .font(.system(size: 20, weight: .semibold))
            HStack {
                CircleHeaderButton(systemName: "chevron.left") { dismiss() }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 20)
    }

    // MARK: - 검색 섹션

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("향수 명")
                .font(.system(size: 17, weight: .semibold))

            ZStack(alignment: .top) {
                searchField

                if vm.isSearchResultVisible {
                    searchDropdown.padding(.top, 74).zIndex(20)
                }
            }

            if let guide = vm.searchGuideMessage, !guide.isEmpty {
                Text(guide)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            TextField("향수 명을 입력해주세요", text: $vm.searchText)
                .font(.system(size: 15))
                .submitLabel(.search)
                .onSubmit { vm.searchButtonTapped() }

            Button("검색") { vm.searchButtonTapped() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }

    // MARK: - 검색 결과 드롭다운

    private var searchDropdown: some View {
        VStack(spacing: 0) {
            if vm.isSearching {
                HStack { Spacer(); ProgressView(); Spacer() }.padding(.vertical, 20)
            } else if vm.searchResults.isEmpty {
                Text("검색 결과가 없어요")
                    .font(.system(size: 14)).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                ForEach(Array(vm.searchResults.enumerated()), id: \.element.id) { idx, fragrance in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { vm.selectFragrance(fragrance) }
                    } label: {
                        searchResultRow(fragrance)
                    }
                    .buttonStyle(.plain)

                    if idx < vm.searchResults.count - 1 {
                        Divider().padding(.leading, 72)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    /// 검색 결과 행 — 한국어 이름/브랜드 우선 표시
    private func searchResultRow(_ fragrance: FragellaFragrance) -> some View {
        HStack(spacing: 12) {
            // 썸네일 (이미지 없는 결과는 API에서 이미 필터됨)
            KFImage(URL(string: fragrance.imageURL ?? ""))
                .placeholder {
                    RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6))
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                // 한국어 이름 우선, 없으면 영문
                Text(fragrance.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    // 한국어 브랜드 우선
                    Text(fragrance.displayBrand)
                        .font(.system(size: 13)).foregroundColor(.secondary)

                    if !fragrance.mainAccords.isEmpty {
                        Text("|").font(.system(size: 13)).foregroundColor(Color(.systemGray4))

                        ForEach(fragrance.mainAccords.prefix(2), id: \.self) { accord in
                            HStack(spacing: 3) {
                                Circle().frame(width: 4, height: 4).foregroundColor(accord.accordColor)
                                Text(accord).font(.system(size: 13)).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - 선택된 향수 카드

    private func selectedCard(_ fragrance: FragellaFragrance) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6))
                if let url = fragrance.imageURL.flatMap(URL.init) {
                    KFImage(url).resizable().aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 6) {
                Text(fragrance.displayBrand)
                    .font(.system(size: 12)).foregroundColor(.secondary)
                Text(fragrance.displayName)
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                HStack(spacing: 6) {
                    ForEach(fragrance.mainAccords.prefix(3), id: \.self) { a in
                        HStack(spacing: 3) {
                            Circle().frame(width: 5, height: 5).foregroundColor(a.accordColor)
                            Text(a).font(.system(size: 13)).foregroundColor(.secondary)
                        }
                    }
                }
            }
            Spacer()

            Button { withAnimation { vm.clearSelectedFragrance() } } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(14)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 별점 섹션

    private func ratingSection(title: String, value: Binding<Int>, label: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(size: 17, weight: .semibold))

            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= value.wrappedValue ? "star.fill" : "star")
                        .font(.system(size: 32))
                        .foregroundColor(star <= value.wrappedValue ? .primary : Color(.systemGray4))
                        .onTapGesture { value.wrappedValue = star }
                }
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(value.wrappedValue)").font(.system(size: 17, weight: .semibold))
                    Text("/5").font(.system(size: 14)).foregroundColor(.secondary)
                }
                .padding(.leading, 8)
            }

            Text(label).font(.system(size: 13)).foregroundColor(.secondary)
        }
    }

    // MARK: - 무드&이미지 태그 (4-4-4-3-3 고정 레이아웃)

    private var moodTagRows: [[String]] {
        let tags = vm.allMoodTags
        guard tags.count >= 18 else { return [tags] }
        return [
            Array(tags[0..<4]),
            Array(tags[4..<8]),
            Array(tags[8..<12]),
            Array(tags[12..<15]),
            Array(tags[15..<18]),
        ]
    }

    private var moodTagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("분위기&이미지").font(.system(size: 17, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(moodTagRows.indices, id: \.self) { rowIndex in
                    HStack(spacing: 8) {
                        ForEach(moodTagRows[rowIndex], id: \.self) { tag in
                            MoodChip(title: tag, isSelected: vm.selectedMoodTags.contains(tag)) {
                                vm.toggleMoodTag(tag)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - 시향 메모

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("시향 메모").font(.system(size: 17, weight: .semibold))

            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    if vm.memo.isEmpty {
                        Text("향수에 대한 느낌을 자유롭게 기록해주세요 (최소 20자)")
                            .font(.system(size: 15))
                            .foregroundColor(Color(.placeholderText))
                            .padding(.top, 18).padding(.leading, 14)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $vm.memo)
                        .font(.system(size: 15))
                        .frame(minHeight: 140)
                        .padding(.horizontal, 8).padding(.top, 8)
                        .onChange(of: vm.memo) { v in
                            if v.count > 2000 { vm.memo = String(v.prefix(2000)) }
                        }
                }

                Text("\(vm.memoCount)/2000")
                    .font(.system(size: 12))
                    .foregroundColor(vm.memoCount < 20 ? Color(.systemGray3) : .secondary)
                    .padding(.trailing, 12).padding(.bottom, 10)
            }
            .background(Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
        }
    }

    // MARK: - 하단 버튼 바

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button { vm.reset() } label: {
                Text("초기화")
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button { Task { await vm.save() } } label: {
                ZStack {
                    if vm.isSaving { ProgressView().tint(.white) }
                    else {
                        Text("작성 완료하기")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(vm.canSave ? Color.black : Color(.systemGray4))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!vm.canSave || vm.isSaving)
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 20)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -4)
        )
    }
}

// MARK: - 서브뷰

private struct CircleHeaderButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color(.systemGray6)).frame(width: 52, height: 52)
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .semibold)).foregroundColor(.primary)
            }
        }
    }
}

struct MoodChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : Color(.label))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSelected ? Color.black : Color.clear)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1))
        }
    }
}

struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let h = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }
            .reduce(0, +) + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? 0, height: max(h, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var y = bounds.minY
        for row in computeRows(proposal: proposal, subviews: subviews) {
            var x = bounds.minX
            let rh = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for sv in row {
                let s = sv.sizeThatFits(.unspecified)
                sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: s.width, height: s.height))
                x += s.width + spacing
            }
            y += rh + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        let maxW = proposal.width ?? 0
        var rows: [[LayoutSubview]] = [[]]
        var rowW: CGFloat = 0
        for sv in subviews {
            let w = sv.sizeThatFits(.unspecified).width
            if rowW + w > maxW && !rows[rows.count - 1].isEmpty {
                rows.append([]); rowW = 0
            }
            rows[rows.count - 1].append(sv)
            rowW += w + spacing
        }
        return rows
    }
}
