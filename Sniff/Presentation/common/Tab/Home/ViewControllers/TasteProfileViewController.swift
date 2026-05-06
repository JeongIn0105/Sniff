//
//  TasteProfileViewController.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//

import Combine
import RxSwift
import SnapKit
import SwiftUI
import UIKit

final class TasteProfileViewController: UIViewController {

    nonisolated static func koreanFamilyName(_ family: String) -> String {
        switch family {
        case "Soft Floral": return "소프트 플로럴"
        case "Floral": return "플로럴"
        case "Floral Amber": return "플로럴 앰버"
        case "Soft Amber": return "소프트 앰버"
        case "Amber": return "앰버"
        case "Woody Amber": return "우디 앰버"
        case "Woods": return "우디"
        case "Mossy Woods": return "모시 우즈"
        case "Dry Woods": return "드라이 우즈"
        case "Citrus": return "시트러스"
        case "Fruity": return "프루티"
        case "Green": return "그린"
        case "Water": return "워터"
        case "Aromatic": return "아로마틱"
        default: return family
        }
    }

    private let viewModel: TasteProfileScreenViewModel
    private var hostingController: UIHostingController<TasteProfileScreenView>?

    init(profileItem: HomeViewModel.HomeProfileItem, userTasteRepository: UserTasteRepositoryType) {
        viewModel = TasteProfileScreenViewModel(
            profileItem: profileItem,
            userTasteRepository: userTasteRepository
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHostingView()
        viewModel.recordAndFetchHistory()
    }
}

private extension TasteProfileViewController {
    func setupHostingView() {
        view.backgroundColor = .systemBackground

        let rootView = TasteProfileScreenView(
            viewModel: viewModel,
            onBack: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onInfo: { [weak self] in
                self?.presentColorInfo()
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

    func presentColorInfo() {
        let infoVC = TasteProfileColorInfoViewController()
        if let sheet = infoVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(infoVC, animated: true)
    }
}

private final class TasteProfileScreenViewModel: ObservableObject {
    let profileItem: HomeViewModel.HomeProfileItem
    @Published private(set) var historyEntries: [TasteProfileHistoryEntry] = []
    @Published var isHistoryExpanded = false

    private let userTasteRepository: UserTasteRepositoryType
    private let disposeBag = DisposeBag()
    private let collapsedHistoryCount = 2
    private let maxVisibleHistoryCount = 5

    var currentEntryId: String? {
        historyEntries.first?.id
    }

    var visibleHistoryEntries: [TasteProfileHistoryEntry] {
        isHistoryExpanded
            ? historyEntries
            : Array(historyEntries.prefix(collapsedHistoryCount))
    }

    var canToggleHistory: Bool {
        historyEntries.count > collapsedHistoryCount
    }

    init(
        profileItem: HomeViewModel.HomeProfileItem,
        userTasteRepository: UserTasteRepositoryType
    ) {
        self.profileItem = profileItem
        self.userTasteRepository = userTasteRepository
    }

    func recordAndFetchHistory() {
        userTasteRepository.recordTasteProfileHistoryIfNeeded(
            profile: profileItem.profile,
            collectionCount: profileItem.collectionCount,
            tastingCount: profileItem.tastingCount
        )
        .observe(on: MainScheduler.instance)
        .subscribe(onSuccess: { [weak self] entries in
            guard let self else { return }
            if entries.isEmpty {
                self.fetchHistory()
            } else {
                self.applyHistory(entries)
            }
        }, onFailure: { [weak self] _ in
            self?.fetchHistory()
        })
        .disposed(by: disposeBag)
    }

    func helperText() -> String {
        switch profileItem.profile.stage {
        case .onboardingOnly:
            return AppStrings.DomainDisplay.TasteProfile.needsCollectionOrRecord
        case .onboardingCollection:
            return AppStrings.DomainDisplay.TasteProfile.needsTastingRecord
        case .earlyTasting, .heavyTasting:
            return "향수를 등록하거나 시향 기록을 남기면 취향이 계속 업데이트돼요"
        }
    }

    func analysisText() -> String {
        let profile = profileItem.profile
        let summary = profile.analysisSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !summary.isEmpty { return summary }

        let parts = [
            profileItem.tastingCount > 0 ? AppStrings.DomainDisplay.TasteProfile.tastingCount(profileItem.tastingCount) : nil,
            profileItem.collectionCount > 0 ? AppStrings.DomainDisplay.TasteProfile.collectionCount(profileItem.collectionCount) : nil
        ]
        .compactMap { $0 }
        .joined(separator: ", ")

        if !parts.isEmpty {
            return "\(parts)을 기반으로 취향을 정리했어요."
        }

        let safeStartingPoint = profile.safeStartingPoint.trimmingCharacters(in: .whitespacesAndNewlines)
        return safeStartingPoint.isEmpty
            ? AppStrings.DomainDisplay.TasteProfile.needsCollectionOrRecord
            : safeStartingPoint
    }

    func majorFamilyRatios() -> [(family: String, ratio: Double)] {
        Self.majorFamilyRatios(from: profileItem.profile.scentVector)
    }

    func toggleHistory() {
        isHistoryExpanded.toggle()
    }

    private func fetchHistory() {
        userTasteRepository.fetchTasteProfileHistory()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] entries in
                self?.applyHistory(entries)
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    private func applyHistory(_ entries: [TasteProfileHistoryEntry]) {
        let sorted = entries.sorted {
            ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
        }
        historyEntries = Array(sorted.prefix(maxVisibleHistoryCount))
        isHistoryExpanded = false
    }

    private static func majorFamilyRatios(from scentVector: [String: Double]) -> [(family: String, ratio: Double)] {
        let grouped = scentVector.reduce(into: [String: Double]()) { result, pair in
            guard let majorFamily = majorFamily(for: pair.key) else { return }
            result[majorFamily, default: 0] += pair.value
        }

        return ["플로럴", "앰버", "우디", "프레쉬"].map { family in
            (family: family, ratio: grouped[family, default: 0])
        }
    }

    private static func majorFamily(for family: String) -> String? {
        switch family {
        case "Floral", "Soft Floral", "Floral Amber":
            return "플로럴"
        case "Soft Amber", "Amber", "Woody Amber":
            return "앰버"
        case "Woods", "Mossy Woods", "Dry Woods":
            return "우디"
        case "Citrus", "Fruity", "Green", "Water", "Aromatic":
            return "프레쉬"
        default:
            return nil
        }
    }
}

private struct TasteProfileScreenView: View {
    @ObservedObject var viewModel: TasteProfileScreenViewModel
    let onBack: () -> Void
    let onInfo: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, 8)

                TasteProfileSummaryCard(viewModel: viewModel)
                    .padding(.top, 24)

                helperView
                    .padding(.top, 16)

                historySection
                    .padding(.top, 28)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            Text(AppStrings.Home.tasteProfileTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)

            Button(action: onInfo) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
    }

    private var helperView: some View {
        HStack(alignment: .top, spacing: 4) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(Color(red: 0.87, green: 0.87, blue: 0.87))
                .frame(width: 20, height: 20)

            Text(viewModel.helperText())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(red: 0.98, green: 0.97, blue: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var historySection: some View {
        if !viewModel.historyEntries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("취향 프로필 히스토리")
                    .font(.custom("Pretendard-SemiBold", size: 18))
                    .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.13))

                VStack(spacing: 0) {
                    ForEach(Array(viewModel.visibleHistoryEntries.enumerated()), id: \.element.id) { index, entry in
                        TasteProfileHistoryRow(
                            entry: entry,
                            isCurrent: entry.id == viewModel.currentEntryId
                        )

                        if index < viewModel.visibleHistoryEntries.count - 1 {
                            Divider()
                        }
                    }

                    if viewModel.canToggleHistory {
                        if !viewModel.visibleHistoryEntries.isEmpty {
                            Divider()
                        }
                        Button(action: viewModel.toggleHistory) {
                            HStack(spacing: 6) {
                                Text(viewModel.isHistoryExpanded ? "접기" : "더보기")
                                Image(systemName: viewModel.isHistoryExpanded ? "chevron.up" : "chevron.down")
                            }
                            .font(.custom("Pretendard-Medium", size: 14))
                            .foregroundColor(Color(red: 0.39, green: 0.39, blue: 0.39))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

private struct TasteProfileSummaryCard: View {
    @ObservedObject var viewModel: TasteProfileScreenViewModel

    private var profile: UserTasteProfile { viewModel.profileItem.profile }
    private var highlightedFamilies: Set<String> {
        Set(
            viewModel.majorFamilyRatios()
                .sorted {
                    if $0.ratio != $1.ratio { return $0.ratio > $1.ratio }
                    return $0.family < $1.family
                }
                .prefix(2)
                .filter { $0.ratio > 0 }
                .map(\.family)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                TasteProfileGradientIcon(
                    title: profile.displayTitle,
                    fallbackFamilies: Array(profile.displayFamilies.prefix(3))
                )
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.displayTitle)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Text(profile.displayMajorSummary)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.30, green: 0.30, blue: 0.30))
                        .lineLimit(1)
                }
            }

            VStack(spacing: 20) {
                ForEach(viewModel.majorFamilyRatios(), id: \.family) { item in
                    TasteProfileRatioRow(
                        family: item.family,
                        ratio: item.ratio,
                        isHighlighted: highlightedFamilies.contains(item.family)
                    )
                }
            }
            .padding(.top, 28)

            Text(viewModel.analysisText())
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.39, green: 0.39, blue: 0.39))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 28)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct TasteProfileRatioRow: View {
    let family: String
    let ratio: Double
    let isHighlighted: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(uiColor: ScentFamilyColor.barColor(for: family)))
                    .frame(width: 9, height: 9)

                Text(family)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.30, green: 0.30, blue: 0.30))

                Spacer(minLength: 12)

                Text("\(Int((ratio * 100).rounded()))%")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(isHighlighted ? Color(red: 0.13, green: 0.13, blue: 0.13) : Color(red: 0.60, green: 0.60, blue: 0.60))
                    .frame(width: 43, alignment: .trailing)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(red: 0.93, green: 0.93, blue: 0.95))

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(uiColor: ScentFamilyColor.barColor(for: family)))
                        .frame(width: proxy.size.width * max(ratio, 0.02))
                }
            }
            .frame(height: 8)
            .padding(.leading, 17)
            .padding(.trailing, 55)
        }
    }
}

private struct TasteProfileHistoryRow: View {
    let entry: TasteProfileHistoryEntry
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 12) {
            TasteProfileGradientIcon(title: entry.title, fallbackFamilies: entry.families)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.custom("Pretendard-Medium", size: 16))
                    .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.13))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.custom("Pretendard-Medium", size: 12))
                    .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if isCurrent {
                Text("적용중")
                    .font(.custom("Pretendard-Medium", size: 13))
                    .foregroundColor(Color(red: 0.52, green: 0.50, blue: 0.48))
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(Color(red: 0.96, green: 0.93, blue: 0.89))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 14)
    }

    private var subtitle: String {
        let families = entry.families.prefix(2)
            .map(TasteProfileViewController.koreanFamilyName(_:))
            .joined(separator: " · ")
        return families.isEmpty ? "" : "\(families) 중심"
    }
}

private struct TasteProfileGradientIcon: View {
    let title: String
    let fallbackFamilies: [String]

    var body: some View {
        RadialGradient(
            gradient: Gradient(colors: gradientColors),
            center: UnitPoint(x: 0.5, y: 0.04),
            startRadius: 0,
            endRadius: 54
        )
    }

    private var gradientColors: [Color] {
        if let exactPreset = TasteProfileGradientIconView.profilePreset(forTitle: title) {
            return exactPreset.colors.map { Color(uiColor: $0) }
        }

        if let palette = FragranceProfileText.profileColorPalette(forTitle: title) {
            return [
                Color(uiColor: UIColor(hex: palette.accentHex)),
                Color(uiColor: UIColor(hex: palette.primaryHex)),
                Color(uiColor: UIColor(hex: palette.baseHex))
            ]
        }

        let base = Color(red: Double(0xF1) / 255.0, green: Double(0xE8) / 255.0, blue: Double(0xDF) / 255.0)
        guard let first = fallbackFamilies.first else {
            return [
                Color(uiColor: UIColor(red: 1.0, green: 0.67, blue: 0.49, alpha: 1)),
                Color(uiColor: UIColor(red: 0.95, green: 0.90, blue: 0.68, alpha: 1)),
                base
            ]
        }

        let firstColor = Color(uiColor: ScentFamilyColor.color(for: first).softened(amount: 0.30))
        let secondColor = Color(uiColor: ScentFamilyColor.color(for: fallbackFamilies.dropFirst().first ?? first).softened(amount: 0.20))
        return [secondColor, firstColor, base]
    }
}
