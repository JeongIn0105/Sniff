//
//  OwnedPerfumeEditSheetView.swift
//  Sniff
//

import SwiftUI
import Kingfisher

struct OwnedPerfumeEditSheetView: View {
    private enum Layout {
        static let horizontalPadding: CGFloat = 20
        static let maxMemoLength = 100
    }

    let perfume: CollectedPerfume
    let onSave: (CollectedPerfumeRegistrationInfo) -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void

    @State private var selectedStatus: CollectedPerfumeUsageStatus
    @State private var selectedFrequency: CollectedPerfumeUsageFrequency
    @State private var selectedPreference: CollectedPerfumePreferenceLevel
    @State private var memo: String
    @State private var showsDeleteAlert = false

    init(
        perfume: CollectedPerfume,
        onSave: @escaping (CollectedPerfumeRegistrationInfo) -> Void,
        onCancel: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.perfume = perfume
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
        _selectedStatus = State(initialValue: perfume.usageStatus ?? .inUse)
        _selectedFrequency = State(initialValue: perfume.usageFrequency ?? .sometimes)
        _selectedPreference = State(initialValue: perfume.preferenceLevel ?? .liked)
        _memo = State(initialValue: perfume.memo ?? "")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("내 보유 정보 수정")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    Text("\(perfume.registrationEditCount)/\(CollectedPerfumeEditPolicy.maxRegistrationEditCount) 수정가능횟수")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(.systemGray2))
                }

                perfumeContextCard

                optionGroup(
                    title: "사용 상태",
                    options: CollectedPerfumeUsageStatus.allCases,
                    selection: $selectedStatus
                )

                optionGroup(
                    title: "사용 빈도",
                    options: CollectedPerfumeUsageFrequency.allCases,
                    selection: $selectedFrequency
                )

                optionGroup(
                    title: "취향 강도",
                    options: CollectedPerfumePreferenceLevel.allCases,
                    selection: $selectedPreference
                )

                memoSection
                actionButtons
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 28)
            .padding(.bottom, 28)
        }
        .background(Color(.systemBackground))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .alert("보유 해제", isPresented: $showsDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("해제", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("이 향수를 보유 목록에서 해제할까요?")
        }
    }

    private var perfumeContextCard: some View {
        HStack(spacing: 18) {
            CollectedPerfumeThumbnailView(imageURL: perfume.imageUrl, size: 58)

            VStack(alignment: .leading, spacing: 5) {
                Text(PerfumePresentationSupport.displayBrand(perfume.brand))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.systemGray2))
                    .lineLimit(1)

                Text(PerfumePresentationSupport.displayPerfumeName(perfume.name))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(height: 96)
        .background(Color(hex: "#F7F7FA"))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#E7E7E7"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func optionGroup<Value: Hashable>(
        title: String,
        options: [Value],
        selection: Binding<Value>
    ) -> some View {
        CollectedPerfumeOptionGroup(
            title: title,
            options: options,
            selectedValue: selection.wrappedValue,
            isRequiredTitle: true,
            titleFontSize: 16,
            cornerRadius: 13,
            onSelect: { selection.wrappedValue = $0 }
        )
    }

    private var memoSection: some View {
        CollectedPerfumeMemoEditor(
            text: memoBinding,
            titleFontSize: 16,
            height: 94,
            countText: "\(memo.count) / \(Layout.maxMemoLength)",
            placeholderColor: Color(hex: "#C9C9C9")
        )
    }

    private var memoBinding: Binding<String> {
        Binding(
            get: { memo },
            set: { memo = String($0.prefix(Layout.maxMemoLength)) }
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 18) {
            Button {
                onSave(
                    CollectedPerfumeRegistrationInfo(
                        usageStatus: selectedStatus,
                        usageFrequency: selectedFrequency,
                        preferenceLevel: selectedPreference,
                        memo: memo
                    )
                )
            } label: {
                Text("저장하기")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(Color(hex: "#111111"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)

            Button("취소") {
                onCancel()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color(.systemGray2))
            .frame(height: 34)

            Divider()
                .padding(.top, 8)

            Button("보유 해제") {
                showsDeleteAlert = true
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.red)
            .frame(height: 44)
        }
    }

}

struct CollectedPerfumeThumbnailView: View {
    let imageURL: String?
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "#EEEAE3"))

            if let imageURL, let url = URL(string: imageURL) {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color(.systemGray3))
                    }
                    .scaledToFit()
                    .padding(6)
            } else {
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color(hex: "#BDB7AC"))
                        .frame(width: size * 0.18, height: size * 0.12)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#BDB7AC"))
                        .frame(width: size * 0.34, height: size * 0.52)
                }
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct CollectedPerfumeOptionGroup<Value: Hashable>: View {
    let title: String
    let options: [Value]
    let selectedValue: Value?
    var isEnabled: Bool = true
    var isRequiredTitle: Bool = false
    var titleFontSize: CGFloat = 17
    var cornerRadius: CGFloat = 13
    let onSelect: (Value) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            titleView

            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = selectedValue == option

                    Button {
                        onSelect(option)
                    } label: {
                        Text(displayName(for: option))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isSelected ? Color(hex: "#8A6F55") : Color(.systemGray))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(isSelected ? Color.sniffBeige : Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .stroke(isSelected ? Color(hex: "#D8C5B4") : Color(.systemGray5), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isEnabled)
                }
            }
        }
    }

    @ViewBuilder
    private var titleView: some View {
        if isRequiredTitle {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(title)
                    .font(.system(size: titleFontSize, weight: .bold))
                    .foregroundColor(.primary)

                Text("필수")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
        } else {
            Text(title)
                .font(.system(size: titleFontSize, weight: .bold))
                .foregroundColor(.primary)
        }
    }

    private func displayName(for option: Value) -> String {
        switch option {
        case let status as CollectedPerfumeUsageStatus:
            return status.displayName
        case let frequency as CollectedPerfumeUsageFrequency:
            return frequency.displayName
        case let preference as CollectedPerfumePreferenceLevel:
            return preference.displayName
        default:
            return "\(option)"
        }
    }
}

struct CollectedPerfumeMemoEditor: View {
    @Binding var text: String
    var title: String = "메모"
    var optionalText: String = "선택"
    var titleFontSize: CGFloat = 17
    var height: CGFloat = 96
    var countText: String?
    var isEnabled: Bool = true
    var disabledMessage: String?
    var placeholder: String = "자유롭게 남겨주세요"
    var placeholderColor: Color = Color(.systemGray2)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: titleFontSize, weight: .bold))
                    .foregroundColor(.primary)

                Text(optionalText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.systemGray2))
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .frame(height: height)
                    .scrollContentBackground(.hidden)
                    .disabled(!isEnabled)

                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(placeholderColor)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 17)
                }

                if let disabledMessage, !isEnabled {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                        Text(disabledMessage)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.systemGray))
                    .padding(.horizontal, 17)
                    .padding(.top, max(0, height - 42))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if let countText, isEnabled {
                    Text(countText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.systemGray3))
                        .padding(.trailing, 18)
                        .padding(.bottom, 14)
                }
            }
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        Color(.systemGray5),
                        style: StrokeStyle(lineWidth: 1, dash: isEnabled ? [] : [5, 4])
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
