//
//  CollectedPerfumeRegistrationViewController.swift
//  Sniff
//
//  Created by Codex on 2026.05.04.
//

import Kingfisher
import SnapKit
import SwiftUI
import UIKit

final class CollectedPerfumeRegistrationViewController: UIViewController {
    var onRegister: ((CollectedPerfumeRegistrationInfo) -> Void)?
    var onRetrySearch: (() -> Void)?

    private let perfume: Perfume
    private var hostingController: UIHostingController<CollectedPerfumeRegistrationView>?

    init(perfume: Perfume) {
        self.perfume = perfume
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = ""

        let rootView = CollectedPerfumeRegistrationView(
            perfume: perfume,
            onBack: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onRetrySearch: { [weak self] in
                guard let self else { return }
                self.navigationController?.popViewController(animated: true)
                self.onRetrySearch?()
            },
            onRegister: { [weak self] info in
                self?.onRegister?(info)
            }
        )

        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .systemBackground
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        hostingController.didMove(toParent: self)
        self.hostingController = hostingController
    }
}

private struct CollectedPerfumeRegistrationView: View {
    private enum ContentTab {
        case perfumeInfo
        case directInput
    }

    private enum Layout {
        static let horizontalPadding: CGFloat = 20
        static let memoHeight: CGFloat = 150
        static let maxMemoLength = 100
    }

    let perfume: Perfume
    let onBack: () -> Void
    let onRetrySearch: () -> Void
    let onRegister: (CollectedPerfumeRegistrationInfo) -> Void

    @State private var selectedTab: ContentTab = .directInput
    @State private var selectedStatus: CollectedPerfumeUsageStatus = .inUse
    @State private var selectedFrequency: CollectedPerfumeUsageFrequency = .sometimes
    @State private var selectedPreference: CollectedPerfumePreferenceLevel = .liked
    @State private var memo = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    perfumeCard
                    tabSelector

                    switch selectedTab {
                    case .perfumeInfo:
                        perfumeInfoContent
                    case .directInput:
                        directInputContent
                    }
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }

            bottomRegisterButton
        }
        .background(Color(.systemBackground))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36, alignment: .leading)
            }
            .buttonStyle(.plain)

            Text("보유 향수 등록")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .frame(height: 36)
    }

    private var perfumeCard: some View {
        HStack(spacing: 16) {
            perfumeThumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(PerfumePresentationSupport.displayBrand(perfume.brand))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(1)

                Text(PerfumePresentationSupport.displayPerfumeName(perfume.name))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onRetrySearch) {
                    Text("다시 검색")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#F1ECE6"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(hex: "#F7F7FA"))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var perfumeThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))

            if let imageUrl = perfume.imageUrl, let url = URL(string: imageUrl) {
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
                        .frame(width: 13, height: 9)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: "#BDB7AC"))
                        .frame(width: 30, height: 44)
                }
            }
        }
        .frame(width: 72, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var tabSelector: some View {
        HStack(spacing: 8) {
            tabButton(title: "향수 정보", tab: .perfumeInfo)
            tabButton(title: "직접 입력할 정보", tab: .directInput)
        }
        .frame(height: 42)
    }

    private func tabButton(title: String, tab: ContentTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isSelected ? Color(hex: "#1F1F1F") : Color(hex: "#F3F3F5"))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var perfumeInfoContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            infoSection(
                title: "사용 정보",
                rows: [
                    ("농도", PerfumePresentationSupport.displayConcentration(perfume.concentration)),
                    ("지속력", PerfumePresentationSupport.displayLongevity(perfume.longevity)),
                    ("확산력", PerfumePresentationSupport.displaySillage(perfume.sillage))
                ]
            )

            chipSection(
                title: "향 계열",
                values: PerfumePresentationSupport.displayAccords(perfume.mainAccords)
            )

            infoSection(
                title: "노트",
                rows: [
                    (AppStrings.UIKitScreens.PerfumeDetail.topNotes, joinedNotes(perfume.topNotes)),
                    (AppStrings.UIKitScreens.PerfumeDetail.middleNotes, joinedNotes(perfume.middleNotes)),
                    (AppStrings.UIKitScreens.PerfumeDetail.baseNotes, joinedNotes(perfume.baseNotes))
                ]
            )

            chipSection(
                title: "계절",
                values: displaySeasons(for: perfume)
            )
        }
    }

    private var directInputContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("직접 입력할 정보")

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
                title: "내 취향 정도",
                options: CollectedPerfumePreferenceLevel.allCases,
                selection: $selectedPreference
            )

            memoSection
        }
    }

    private func infoSection(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title)

            ForEach(rows, id: \.0) { title, value in
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.secondaryLabel))
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text(value)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func chipSection(title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title)

            FlowLayout(spacing: 8) {
                ForEach((values.isEmpty ? ["-"] : values), id: \.self) { value in
                    Text(value)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .padding(.horizontal, 16)
                        .frame(height: 34)
                        .background(Color(hex: "#F3F3F5"))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func optionGroup<Value: Hashable>(
        title: String,
        options: [Value],
        selection: Binding<Value>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title)

            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = selection.wrappedValue == option

                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Text(displayName(for: option))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isSelected ? .primary : Color(.systemGray))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(isSelected ? Color(.systemBackground) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isSelected ? Color(.systemGray4) : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color(hex: "#EFEFF1"))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
    }

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                sectionTitle("메모")

                Text("(선택)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: memoBinding)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(height: Layout.memoHeight)
                    .scrollContentBackground(.hidden)

                if memo.isEmpty {
                    Text("자유롭게 남겨주세요")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(.placeholderText))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var memoBinding: Binding<String> {
        Binding(
            get: { memo },
            set: { memo = String($0.prefix(Layout.maxMemoLength)) }
        )
    }

    private var bottomRegisterButton: some View {
        VStack(spacing: 0) {
            Button {
                onRegister(
                    CollectedPerfumeRegistrationInfo(
                        usageStatus: selectedStatus,
                        usageFrequency: selectedFrequency,
                        preferenceLevel: selectedPreference,
                        memo: memo
                    )
                )
            } label: {
                Text("등록하기")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(hex: "#1F1F1F"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.primary)
    }

    private func joinedNotes(_ notes: [String]?) -> String {
        let displayNotes = PerfumePresentationSupport.displayNotes(notes ?? [])
        return displayNotes.isEmpty ? "-" : displayNotes.joined(separator: ", ")
    }

    private func displaySeasons(for perfume: Perfume) -> [String] {
        let rankedSeasons = perfume.seasonRanking
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .prefix(2)
            .map(\.name)
        let seasons = rankedSeasons.isEmpty ? (perfume.season ?? []) : Array(rankedSeasons)
        return PerfumePresentationSupport.displaySeasons(seasons)
    }

    private func displayName<Value>(for option: Value) -> String {
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
