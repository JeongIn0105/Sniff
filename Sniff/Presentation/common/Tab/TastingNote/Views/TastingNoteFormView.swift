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
                VStack(alignment: .leading, spacing: 0) {
                    perfumeInputSection
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)

                    formSectionDivider

                    ratingSection
                        .padding(.horizontal, 20)
                        .padding(.top, 40)
                        .padding(.bottom, 24)

                    moodTagSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 0)

                    if vm.shouldShowUsageContext {
                        usageContextSection
                            .padding(.horizontal, 20)
                            .padding(.top, 36)
                            .padding(.bottom, 0)
                    }

                    if vm.usesOwnedPerfumeWritingMode {
                        wearPerformanceSection
                            .padding(.horizontal, 20)
                            .padding(.top, 36)
                            .padding(.bottom, 0)

                        wearContextSection
                            .padding(.horizontal, 20)
                            .padding(.top, 36)
                            .padding(.bottom, 0)
                    }

                    memoSection
                        .padding(.horizontal, 20)
                        .padding(.top, 42)
                        .padding(.bottom, 16)

                    Spacer().frame(height: 72)
                }
            }

            // 하단 버튼 바
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

    // MARK: - 헤더 (와이어프레임: 좌측 정렬 chevron + 제목)

    private var headerView: some View {
        HStack(spacing: 0) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Text(vm.navigationTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - 시향 향수 입력 섹션

    private var perfumeInputSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(vm.perfumeSectionTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            if vm.shouldShowOwnedPerfumePicker {
                ownedPerfumePickerSection
                    .padding(.top, 16)
            }

            clearableTextField(
                title: vm.perfumeNameFieldTitle,
                placeholder: vm.perfumeNamePlaceholder,
                text: $vm.perfumeName,
                isEnabled: vm.isPerfumeIdentityEditable
            )
            .padding(.top, vm.shouldShowOwnedPerfumePicker ? 24 : 16)

            clearableTextField(
                title: vm.brandFieldTitle,
                placeholder: vm.brandPlaceholder,
                text: $vm.brandName,
                isEnabled: vm.isPerfumeIdentityEditable
            )
            .padding(.top, 24)
        }
    }

    private var ownedPerfumePickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("사용할 보유 향수")
                .font(.custom("Pretendard", size: 14).weight(.regular))
                .foregroundColor(.primary)

            if vm.isLoadingOwnedPerfumes {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("보유 향수를 불러오는 중")
                        .font(.custom("Pretendard", size: 14).weight(.regular))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .frame(height: 54)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else if vm.ownedPerfumes.isEmpty {
                Text(vm.ownedPerfumePickerHint)
                    .font(.custom("Pretendard", size: 14).weight(.regular))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .frame(height: 54)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.ownedPerfumes) { perfume in
                        ownedPerfumeSelectionRow(perfume)
                    }
                }
            }

            if !vm.ownedPerfumes.isEmpty {
                Text(vm.ownedPerfumePickerHint)
                    .font(.custom("Pretendard", size: 13).weight(.regular))
                    .foregroundColor(Color(.systemGray2))
            }
        }
    }

    private func ownedPerfumeSelectionRow(_ perfume: CollectedPerfume) -> some View {
        let isSelected = vm.selectedOwnedPerfumeID == perfume.id
        return Button {
            vm.selectOwnedPerfume(perfume)
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(PerfumePresentationSupport.displayPerfumeName(perfume.name))
                        .font(.custom("Pretendard", size: 15).weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(PerfumePresentationSupport.displayBrand(perfume.brand))
                        .font(.custom("Pretendard", size: 13).weight(.regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 14)
            .frame(height: 58)
            .background(isSelected ? Color(red: 0.96, green: 0.94, blue: 0.90) : Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color(red: 0.86, green: 0.84, blue: 0.80) : Color(.systemGray4), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var formSectionDivider: some View {
        Rectangle()
            .fill(Color(.systemGray6))
            .frame(maxWidth: .infinity)
            .frame(height: 8)
    }

    // MARK: - X 버튼이 있는 텍스트 필드 (와이어프레임: 입력 시 오른쪽에 xmark 표시)

    private func clearableTextField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isEnabled: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Pretendard", size: 14).weight(.regular))
                .foregroundColor(.primary)

            HStack(spacing: 0) {
                TextField(placeholder, text: text)
                    .font(.custom("Pretendard", size: 18).weight(.regular))
                    .foregroundColor(isEnabled ? .primary : .secondary)
                    .disabled(!isEnabled)
                    .submitLabel(.next)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(maxWidth: .infinity)
                    .padding(.leading, 18)
                    .padding(.trailing, text.wrappedValue.isEmpty ? 18 : 10)

                // 입력 값이 있을 때만 X 버튼 표시
                if isEnabled && !text.wrappedValue.isEmpty {
                    Button {
                        text.wrappedValue = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                            .frame(width: 24, height: 24)
                    }
                    .padding(.trailing, 18)
                }
            }
            .frame(height: 56)
            .background(isEnabled ? Color(.systemBackground) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.86, green: 0.86, blue: 0.86), lineWidth: 1)
            )
        }
    }

    // MARK: - 향 선호도 섹션 (와이어프레임: 0점일 때 힌트 텍스트 표시)

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(vm.ratingSectionTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(1...5, id: \.self) { star in
                        ratingStarButton(star)
                    }
                }
                .frame(width: 260, height: 44, alignment: .leading)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(vm.rating)")
                        .font(.custom("Pretendard", size: 20).weight(.bold))
                        .foregroundColor(.primary)
                    Text("/5")
                        .font(.custom("Pretendard", size: 14).weight(.regular))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
            }

            // 0점: 입력 안내 힌트 / 그 외: 선택 라벨
            if vm.rating == 0 {
                Text(vm.ratingHintText)
                    .font(.custom("Pretendard", size: 15).weight(.medium))
                    .foregroundColor(Color(red: 0.72, green: 0.72, blue: 0.72))
            } else {
                Text(vm.rating.ratingLabel)
                .font(.custom("Pretendard", size: 13).weight(.regular))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func ratingStarButton(_ star: Int) -> some View {
        let isSelected = star <= vm.rating
        return ZStack {
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(isSelected ? .black : Color(red: 0.93, green: 0.93, blue: 0.93))

            if !isSelected {
                Text("\(star)")
                    .font(.custom("Pretendard", size: 18).weight(.bold))
                    .foregroundColor(.white.opacity(0.95))
                    .offset(y: -1)
            }
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .onTapGesture { vm.rating = star }
    }

    // MARK: - 분위기&이미지 태그 섹션

    private var moodTagRows: [[String]] {
        let tags = vm.allMoodTags
        guard tags.count >= 18 else { return [tags] }
        return [
            Array(tags[0..<4]),
            Array(tags[4..<8]),
            Array(tags[8..<12]),
            Array(tags[12..<15]),
            Array(tags[15..<18])
        ]
    }

    private var moodTagSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(vm.moodSectionTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 7) {
                ForEach(moodTagRows.indices, id: \.self) { rowIndex in
                    HStack(spacing: 7) {
                        ForEach(moodTagRows[rowIndex], id: \.self) { tag in
                            MoodChip(
                                title: tag,
                                isSelected: vm.selectedMoodTags.contains(tag)
                            ) {
                                vm.toggleMoodTag(tag)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private var usageContextSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(vm.usageContextTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            chipFlow {
                ForEach(vm.allUsageContexts, id: \.self) { context in
                    MoodChip(title: context, isSelected: vm.usageContext == context) {
                        vm.toggleUsageContext(context)
                    }
                }
            }
        }
    }

    private var wearPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("착용감")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            singleChoiceSection(
                title: "지속력",
                options: vm.allLongevityExperiences,
                selection: vm.longevityExperience,
                action: vm.toggleLongevityExperience
            )

            singleChoiceSection(
                title: "발향감",
                options: vm.allSillageExperiences,
                selection: vm.sillageExperience,
                action: vm.toggleSillageExperience
            )

            singleChoiceSection(
                title: "드라이다운 변화",
                options: vm.allDrydownChanges,
                selection: vm.drydownChange,
                action: vm.toggleDrydownChange
            )

            singleChoiceSection(
                title: "피부 궁합",
                options: vm.allSkinChemistries,
                selection: vm.skinChemistry,
                action: vm.toggleSkinChemistry
            )
        }
    }

    private var wearContextSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("착용 컨텍스트")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            multiChoiceSection(
                title: "착용 상황",
                options: vm.allWearSituations,
                selections: vm.selectedWearSituations,
                action: vm.toggleWearSituation
            )

            multiChoiceSection(
                title: "계절 / 날씨",
                options: vm.allWeatherContexts,
                selections: vm.selectedWeatherContexts,
                action: vm.toggleWeatherContext
            )

            multiChoiceSection(
                title: "착용 부위",
                options: vm.allApplicationAreas,
                selections: vm.selectedApplicationAreas,
                action: vm.toggleApplicationArea
            )
        }
    }

    private func singleChoiceSection(
        title: String,
        options: [String],
        selection: String?,
        action: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.custom("Pretendard", size: 14).weight(.regular))
                .foregroundColor(.primary)

            chipFlow {
                ForEach(options, id: \.self) { option in
                    MoodChip(title: option, isSelected: selection == option) {
                        action(option)
                    }
                }
            }
        }
    }

    private func multiChoiceSection(
        title: String,
        options: [String],
        selections: Set<String>,
        action: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.custom("Pretendard", size: 14).weight(.regular))
                .foregroundColor(.primary)

            chipFlow {
                ForEach(options, id: \.self) { option in
                    MoodChip(title: option, isSelected: selections.contains(option)) {
                        action(option)
                    }
                }
            }
        }
    }

    private func chipFlow<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ChipFlowLayout(spacing: 8) {
            content()
        }
    }

    // MARK: - 시향 메모 섹션

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(vm.memoSectionTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    if vm.memo.isEmpty {
                        Text(vm.memoPlaceholder)
                            .font(.custom("Pretendard", size: 15).weight(.regular))
                            .foregroundColor(Color(.placeholderText))
                            .padding(.top, 18)
                            .padding(.leading, 14)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $vm.memo)
                        .font(.custom("Pretendard", size: 15).weight(.regular))
                        .frame(minHeight: 138)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        .onChange(of: vm.memo) { v in
                            if v.count > vm.maxMemoCount {
                                vm.memo = String(v.prefix(vm.maxMemoCount))
                            }
                        }
                }

                Text("\(vm.memoCount)/\(vm.maxMemoCount)")
                    .font(.custom("Pretendard", size: 12).weight(.regular))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 12)
                    .padding(.bottom, 10)
            }
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )

            Text(vm.memoHelperText)
                .font(.custom("Pretendard", size: 13).weight(.regular))
                .foregroundColor(Color(.systemGray2))
        }
    }

    // MARK: - 하단 버튼 바

    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // 초기화 버튼
                Button { vm.reset() } label: {
                    Text(AppStrings.TastingNoteFormUI.reset)
                        .font(.custom("Pretendard", size: 15).weight(.semibold))
                        .foregroundColor(.primary)
                        .frame(width: 108)
                        .frame(height: 48)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // 작성 완료 버튼 (canSave 시 검정, 아니면 회색)
                Button { Task { await vm.save() } } label: {
                    ZStack {
                        if vm.isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text(vm.saveButtonTitle)
                                .font(.custom("Pretendard", size: 15).weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(vm.canSave ? Color.black : Color(.systemGray4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!vm.canSave || vm.isSaving)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 5)
        .padding(.bottom, 17)
        .background(
            Color(.systemBackground)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - 분위기 칩 서브뷰

struct MoodChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.custom("Pretendard", size: 14).weight(.regular))
                .foregroundColor(Color(.label))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color(red: 0.96, green: 0.94, blue: 0.90) : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color(red: 0.86, green: 0.84, blue: 0.80) : Color(.systemGray4),
                        lineWidth: 1
                    )
                )
        }
    }
}

// MARK: - 칩 플로우 레이아웃

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
