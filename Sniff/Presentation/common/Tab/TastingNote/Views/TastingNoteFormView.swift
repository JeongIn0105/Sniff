//
//  TastingNoteFormView.swift
//  Sniff
//
//  Created by 이정인 on 4/16/26.
//

// MARK: - 등록 / 수정 화면
import SwiftUI

struct TastingNoteFormView: View {

    @StateObject private var vm: TastingNoteFormViewModel
    @Environment(\.dismiss) private var dismiss
    private let onSaveSuccess: (String) -> Void

    init(
        viewModel: TastingNoteFormViewModel,
        onSaveSuccess: @escaping (String) -> Void = { _ in }
    ) {
        _vm = StateObject(wrappedValue: viewModel)
        self.onSaveSuccess = onSaveSuccess
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    perfumeInputSection
                    ratingSection(title: "향 선호도", value: $vm.rating, label: vm.rating.ratingLabel)
                    moodTagSection
                    memoSection
                    Spacer().frame(height: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }

            // 하단 버튼 바 — VStack 안에 배치해 스크롤 콘텐츠가 뒤로 보이지 않도록
            bottomBar
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: vm.saveSuccess) { success in
            if success { onSaveSuccess(vm.savedPerfumeName); dismiss() }
        }
        .alert(AppStrings.TastingNoteFormUI.errorTitle, isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button(AppStrings.TastingNoteFormUI.confirm) { vm.errorMessage = nil }
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
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    // MARK: - 시향 향수 입력

    private var perfumeInputSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("시향 향수")
                .font(.system(size: 17, weight: .semibold))

            formTextField(
                title: "향수 명",
                placeholder: "향수 명을 입력하세요",
                text: $vm.perfumeName
            )

            formTextField(
                title: "브랜드",
                placeholder: "향수 브랜드를 입력하세요",
                text: $vm.brandName
            )
        }
    }

    private func formTextField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.primary)

            TextField(placeholder, text: text)
                .font(.system(size: 16))
                .submitLabel(.next)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }

    // MARK: - 별점 섹션

    private func ratingSection(title: String, value: Binding<Int>, label: String) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title).font(.system(size: 17, weight: .semibold))

            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= value.wrappedValue ? "star.fill" : "star")
                        .font(.system(size: 31))
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
        VStack(alignment: .leading, spacing: 11) {
            Text("분위기&이미지").font(.system(size: 17, weight: .semibold))

            VStack(alignment: .leading, spacing: 7) {
                ForEach(moodTagRows.indices, id: \.self) { rowIndex in
                    HStack(spacing: 7) {
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
        VStack(alignment: .leading, spacing: 11) {
            Text("시향 메모").font(.system(size: 17, weight: .semibold))

            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    if vm.memo.isEmpty {
                        Text(AppStrings.TastingNoteFormUI.memoPlaceholder)
                            .font(.system(size: 15))
                            .foregroundColor(Color(.placeholderText))
                            .padding(.top, 18).padding(.leading, 14)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $vm.memo)
                        .font(.system(size: 15))
                        .frame(minHeight: 138)
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
                Text(AppStrings.TastingNoteFormUI.reset)
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button { Task { await vm.save() } } label: {
                ZStack {
                    if vm.isSaving { ProgressView().tint(.white) }
                    else {
                        Text(AppStrings.TastingNoteFormUI.save)
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(vm.canSave ? Color.black : Color(.systemGray4))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!vm.canSave || vm.isSaving)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(
            Color(.systemBackground)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - 서브뷰

struct MoodChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .white : Color(.label))
                .padding(.horizontal, 13).padding(.vertical, 7)
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
