//
//  FilterViewController.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//

import Combine
import SwiftUI
import SnapKit
import Then
import UIKit

final class FilterViewController: UIViewController {

    private let state: FilterSheetState
    private var hostingController: UIHostingController<FilterSheetView>?

    var onApply: ((SearchFilter) -> Void)?

    init(viewModel: FilterViewModel) {
        self.state = FilterSheetState(
            initialFilter: viewModel.currentFilter,
            perfumes: viewModel.currentPerfumes
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        embedFilterView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentationController?.delegate = self
    }

    private func embedFilterView() {
        let filterView = FilterSheetView(
            state: state,
            onDismiss: { [weak self] in
                self?.applyPendingResetIfNeeded()
                self?.dismiss(animated: true)
            },
            onApply: { [weak self] filter in
                guard let self else { return }
                self.state.didApplyExplicitly = true
                self.state.shouldApplyResetOnDismiss = false
                self.onApply?(filter)
                self.dismiss(animated: true)
            }
        )

        let hostingController = UIHostingController(rootView: filterView).then {
            $0.view.backgroundColor = .systemBackground
        }
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        hostingController.didMove(toParent: self)
        self.hostingController = hostingController
    }

    private func applyPendingResetIfNeeded() {
        guard state.shouldApplyResetOnDismiss, !state.didApplyExplicitly else { return }
        state.shouldApplyResetOnDismiss = false
        onApply?(state.currentFilter)
    }
}

extension FilterViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        applyPendingResetIfNeeded()
    }
}

@MainActor
private final class FilterSheetState: ObservableObject {
    private enum SelectionLimit {
        static let scentFamilies = 3
    }

    @Published var currentFilter: SearchFilter {
        didSet {
            resultCount = SearchFilterEngine.filterPerfumes(perfumes, filter: currentFilter).count
        }
    }

    @Published private(set) var resultCount: Int
    var shouldApplyResetOnDismiss = false
    var didApplyExplicitly = false

    private let perfumes: [Perfume]

    init(initialFilter: SearchFilter, perfumes: [Perfume]) {
        var sanitizedFilter = initialFilter
        sanitizedFilter.moodTags = []
        self.currentFilter = sanitizedFilter
        self.perfumes = perfumes
        self.resultCount = SearchFilterEngine.filterPerfumes(perfumes, filter: sanitizedFilter).count
    }

    var isApplyEnabled: Bool {
        resultCount > 0
    }

    func toggle(_ family: ScentFamilyFilter) {
        var filter = currentFilter
        if filter.scentFamilies.contains(family) {
            filter.scentFamilies.remove(family)
        } else if filter.scentFamilies.count < SelectionLimit.scentFamilies {
            filter.scentFamilies.insert(family)
        } else {
            return
        }
        currentFilter = filter
    }

    func toggle(_ concentration: Concentration) {
        var filter = currentFilter
        if filter.concentrations.contains(concentration) {
            filter.concentrations.remove(concentration)
        } else {
            filter.concentrations = [concentration]
        }
        currentFilter = filter
    }

    func toggle(_ season: Season) {
        var filter = currentFilter
        if filter.seasons.contains(season) {
            filter.seasons.remove(season)
        } else {
            filter.seasons = [season]
        }
        currentFilter = filter
    }

    func reset() {
        currentFilter = SearchFilter()
        shouldApplyResetOnDismiss = true
    }

    func isDisabled(_ family: ScentFamilyFilter) -> Bool {
        !currentFilter.scentFamilies.contains(family)
        && currentFilter.scentFamilies.count >= SelectionLimit.scentFamilies
    }

    func isDimmed(_ family: ScentFamilyFilter) -> Bool {
        isDisabled(family)
    }

    func isDimmed(_ concentration: Concentration) -> Bool {
        !currentFilter.concentrations.isEmpty
        && !currentFilter.concentrations.contains(concentration)
    }

    func isDimmed(_ season: Season) -> Bool {
        !currentFilter.seasons.isEmpty
        && !currentFilter.seasons.contains(season)
    }
}

private struct FilterSheetView: View {
    @ObservedObject var state: FilterSheetState
    let onDismiss: () -> Void
    let onApply: (SearchFilter) -> Void

    @State private var activeInfoSheet: FilterInfoSheet?

    init(
        state: FilterSheetState,
        onDismiss: @escaping () -> Void,
        onApply: @escaping (SearchFilter) -> Void
    ) {
        self.state = state
        self.onDismiss = onDismiss
        self.onApply = onApply
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    FilterSectionView(
                        title: AppStrings.UIKitScreens.Filter.scentFamily,
                        subtitle: "최대 3개 선택 가능",
                        showsInfoButton: true,
                        onInfoTap: { activeInfoSheet = .scentFamily }
                    ) {
                        FlowLayout(spacing: 8) {
                            ForEach(ScentFamilyFilter.allCases, id: \.self) { family in
                                FilterChip(
                                    title: family.displayName,
                                    isSelected: state.currentFilter.scentFamilies.contains(family),
                                    isDimmed: state.isDimmed(family),
                                    isDisabled: state.isDisabled(family)
                                ) {
                                    state.toggle(family)
                                }
                            }
                        }
                    }
                    .padding(.top, 26)
                    .padding(.bottom, 25)

                    Divider()

                    FilterSectionView(
                        title: AppStrings.UIKitScreens.Filter.concentration,
                        subtitle: "최대 1개 선택 가능",
                        showsInfoButton: true,
                        onInfoTap: { activeInfoSheet = .concentration }
                    ) {
                        FlowLayout(spacing: 8) {
                            ForEach(Concentration.allCases, id: \.self) { concentration in
                                FilterChip(
                                    title: concentration.displayName,
                                    isSelected: state.currentFilter.concentrations.contains(concentration),
                                    isDimmed: state.isDimmed(concentration)
                                ) {
                                    state.toggle(concentration)
                                }
                            }
                        }
                    }
                    .padding(.top, 33)
                    .padding(.bottom, 25)

                    Divider()

                    FilterSectionView(
                        title: AppStrings.UIKitScreens.Filter.season,
                        subtitle: "최대 1개 선택 가능",
                        showsInfoButton: false,
                        onInfoTap: {}
                    ) {
                        FlowLayout(spacing: 8) {
                            ForEach(Season.allCases, id: \.self) { season in
                                FilterChip(
                                    title: season.displayName,
                                    isSelected: state.currentFilter.seasons.contains(season),
                                    isDimmed: state.isDimmed(season)
                                ) {
                                    state.toggle(season)
                                }
                            }
                        }
                    }
                    .padding(.top, 33)
                    .padding(.bottom, 24)
                }
            }

            bottomBar
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .sheet(item: $activeInfoSheet) { sheet in
            switch sheet {
            case .scentFamily:
                ScentFamilyInfoSheetView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            case .concentration:
                ConcentrationInfoSheetView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                }

                Text(AppStrings.UIKitScreens.Filter.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 18)

            Divider()
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                state.reset()
            } label: {
                Text(AppStrings.UIKitScreens.Filter.reset)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(.systemGray))
                    .frame(width: 88, height: 48)
                    .background(Color(hex: "#F6F6F8"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                onApply(state.currentFilter)
            } label: {
                Text(AppStrings.UIKitScreens.Filter.applyCount(state.resultCount))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(state.isApplyEnabled ? Color(hex: "#1F1F1F") : Color(hex: "#D9D9D9"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!state.isApplyEnabled)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(
            Color(.systemBackground)
                .overlay(alignment: .top) { Divider() }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct FilterSectionView<Content: View>: View {
    let title: String
    let subtitle: String?
    let showsInfoButton: Bool
    let onInfoTap: () -> Void
    let content: Content

    init(
        title: String,
        subtitle: String?,
        showsInfoButton: Bool,
        onInfoTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsInfoButton = showsInfoButton
        self.onInfoTap = onInfoTap
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                if showsInfoButton {
                    Button(action: onInfoTap) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(.systemGray2))
                    }
                    .buttonStyle(.plain)
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.tertiaryLabel))
                        .padding(.leading, showsInfoButton ? 20 : 26)
                }

                Spacer(minLength: 0)
            }

            content
        }
        .padding(.horizontal, 24)
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var isDimmed: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 18)
                .frame(height: 40)
                .background(backgroundColor)
                .overlay(
                    Capsule()
                        .stroke(borderColor, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var foregroundColor: Color {
        isDimmed || isDisabled ? Color(.systemGray3) : Color(.label)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(red: 0.96, green: 0.93, blue: 0.90)
        }
        return Color(.systemBackground).opacity(isDimmed ? 0.45 : 1)
    }

    private var borderColor: Color {
        if isSelected {
            return Color(red: 0.86, green: 0.83, blue: 0.80)
        }
        return Color(red: 0.87, green: 0.87, blue: 0.87).opacity(isDimmed ? 0.45 : 1)
    }
}

private enum FilterInfoSheet: Identifiable {
    case scentFamily
    case concentration

    var id: String {
        switch self {
        case .scentFamily:
            return "scentFamily"
        case .concentration:
            return "concentration"
        }
    }
}

private struct ConcentrationInfoItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let fillRatio: CGFloat
}

private struct ConcentrationInfoSheetView: View {
    @Environment(\.dismiss) private var dismiss

    private let items: [ConcentrationInfoItem] = [
        .init(title: "퍼퓸", description: "지속 시간 6시간 ~ 12시간", fillRatio: 0.96),
        .init(title: "오 드 퍼퓸(EDP)", description: "지속 시간 4시간 ~ 6시간", fillRatio: 0.72),
        .init(title: "오 드 뚜왈렛(EDT)", description: "지속 시간 2시간 ~ 4시간", fillRatio: 0.52),
        .init(title: "오 드 코롱(EDC)", description: "지속 시간 1시간 ~ 2시간", fillRatio: 0.28),
        .init(title: "오 프레쉬", description: "지속 시간 30분 ~ 1시간", fillRatio: 0.14)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                sheetHeader(title: AppStrings.UIKitScreens.Filter.concentrationInfoTitle)

                Text(AppStrings.UIKitScreens.Filter.concentrationInfoBody)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 26) {
                    ForEach(items) { item in
                        ConcentrationInfoRow(item: item)
                    }
                }
                .padding(.top, 28)
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)
            .padding(.bottom, 28)
        }
        .background(Color(.systemBackground))
    }

    private func sheetHeader(title: String) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct ConcentrationInfoRow: View {
    let item: ConcentrationInfoItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "#F5F5F5"))
                PerfumeBottleIcon(fillRatio: item.fillRatio)
                    .frame(width: 22, height: 26)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 7) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(item.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct PerfumeBottleIcon: View {
    let fillRatio: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let bodyRect = CGRect(x: width * 0.16, y: height * 0.34, width: width * 0.68, height: height * 0.60)
            let inset: CGFloat = 2.2
            let liquidHeight = max(2, (bodyRect.height - inset * 2) * min(max(fillRatio, 0.08), 0.98))

            ZStack {
                Path { path in
                    let rect = CGRect(x: width * 0.23, y: 0, width: width * 0.54, height: height * 0.28)
                    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                    path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.02, y: rect.minY + rect.height * 0.25))
                    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.72))
                    path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
                    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.72))
                    path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.02, y: rect.minY + rect.height * 0.25))
                    path.closeSubpath()
                }
                .fill(Color(hex: "#202020"))

                Rectangle()
                    .fill(Color(hex: "#202020"))
                    .frame(width: width * 0.30, height: height * 0.17)
                    .position(x: width * 0.5, y: height * 0.305)

                RoundedRectangle(cornerRadius: 2.8)
                    .stroke(Color(hex: "#202020"), lineWidth: 1.4)
                    .frame(width: bodyRect.width, height: bodyRect.height)
                    .position(x: bodyRect.midX, y: bodyRect.midY)

                Rectangle()
                    .fill(Color(hex: "#202020"))
                    .frame(width: bodyRect.width - inset * 2, height: liquidHeight)
                    .position(
                        x: bodyRect.midX,
                        y: bodyRect.maxY - inset - liquidHeight / 2
                    )
            }
        }
    }
}

private struct ScentFamilyInfoSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(AppStrings.UIKitScreens.Filter.scentFamilyInfoTitle)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }

                Text(AppStrings.UIKitScreens.Filter.scentFamilyInfoBody)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 28) {
                    ForEach(ScentFamilyFilter.allCases, id: \.self) { family in
                        ScentFamilyInfoRow(family: family)
                    }
                }
                .padding(.top, 34)
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
    }
}

private struct ScentFamilyInfoRow: View {
    let family: ScentFamilyFilter

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(Color(uiColor: ScentFamilyColor.color(for: family.rawValue)))
                .frame(width: 10, height: 10)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 7) {
                Text(family.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(family.descriptionText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}
