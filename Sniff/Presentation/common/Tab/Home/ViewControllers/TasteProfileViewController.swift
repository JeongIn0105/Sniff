//
//  TasteProfileViewController.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//

import UIKit
import SnapKit
import Then
import RxSwift

final class TasteProfileViewController: UIViewController {

    // MARK: - Typography

    private enum Typography {
        static func pretendard(size: CGFloat, weight: UIFont.Weight) -> UIFont {
            let name: String
            switch weight {
            case .semibold: name = "Pretendard-SemiBold"
            case .medium:   name = "Pretendard-Medium"
            case .bold, .heavy, .black: name = "Pretendard-Bold"
            default:        name = "Pretendard-Regular"
            }
            return UIFont(name: name, size: size)
                ?? UIFont(name: "Pretendard-Medium", size: size)
                ?? .systemFont(ofSize: size, weight: weight)
        }
    }

    // MARK: - Family 한국어 변환

    static func koreanFamilyName(_ family: String) -> String {
        switch family {
        case "Soft Floral":   return "소프트 플로럴"
        case "Floral":        return "플로럴"
        case "Floral Amber":  return "플로럴 앰버"
        case "Soft Amber":    return "소프트 앰버"
        case "Amber":         return "앰버"
        case "Woody Amber":   return "우디 앰버"
        case "Woods":         return "우디"
        case "Mossy Woods":   return "모시 우즈"
        case "Dry Woods":     return "드라이 우즈"
        case "Citrus":        return "시트러스"
        case "Fruity":        return "프루티"
        case "Green":         return "그린"
        case "Water":         return "워터"
        case "Aromatic":      return "아로마틱"
        default:              return family
        }
    }

    // MARK: - Properties

    private let profileItem: HomeViewModel.HomeProfileItem
    private let userTasteRepository: UserTasteRepositoryType
    private let disposeBag = DisposeBag()

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .label
    }

    private let titleLabel = UILabel().then {
        $0.text = AppStrings.Home.tasteProfileTitle
        $0.font = .systemFont(ofSize: 20, weight: .semibold)
        $0.textColor = .label
    }

    private let infoButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "exclamationmark.circle"), for: .normal)
        $0.tintColor = .secondaryLabel
    }

    private let cardView = TasteProfileCardView()

    private let helperContainerView = UIView().then {
        $0.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.96, alpha: 1)
        $0.layer.cornerRadius = 14
        $0.layer.cornerCurve = .continuous
    }

    private let helperIconView = UIImageView(image: UIImage(systemName: "exclamationmark.circle")).then {
        $0.tintColor = UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1)
        $0.contentMode = .scaleAspectFit
        $0.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
    }

    private let helperLabel = UILabel().then {
        $0.text = "향수를 등록하거나 시향 기록을 남기면 취향이 더 선명해져요"
        $0.font = .systemFont(ofSize: 12, weight: .semibold)
        $0.textColor = UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1)
        $0.numberOfLines = 0
    }

    private let historyTitleLabel = UILabel().then {
        $0.text = "취향 프로필 히스토리"
        $0.font = UIFont(name: "Pretendard-SemiBold", size: 18)
            ?? UIFont(name: "Pretendard-Bold", size: 18)
            ?? .systemFont(ofSize: 18, weight: .semibold)
        $0.textColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
    }

    private let historyContainerView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 16
        $0.layer.cornerCurve = .continuous
    }

    private let historyStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
    }

    // 현재 적용 중인 히스토리 entry ID (가장 최신)
    private var currentEntryId: String?
    // 히스토리 항목 캐시 (탭 시 entry 조회용)
    private var cachedEntries: [TasteProfileHistoryEntry] = []

    // MARK: - Init

    init(profileItem: HomeViewModel.HomeProfileItem, userTasteRepository: UserTasteRepositoryType) {
        self.profileItem = profileItem
        self.userTasteRepository = userTasteRepository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureContent()
        recordAndFetchHistory()
    }

    // MARK: - Actions

    @objc private func popViewController() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func presentColorInfo() {
        let infoVC = TasteProfileColorInfoViewController()
        if let sheet = infoVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(infoVC, animated: true)
    }
}

// MARK: - Setup

private extension TasteProfileViewController {

    func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [backButton, titleLabel, infoButton, cardView,
         helperContainerView, historyTitleLabel, historyContainerView
        ].forEach { contentView.addSubview($0) }
        [helperIconView, helperLabel].forEach { helperContainerView.addSubview($0) }
        historyContainerView.addSubview(historyStackView)

        backButton.addTarget(self, action: #selector(popViewController), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(presentColorInfo), for: .touchUpInside)

        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        backButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(28)
        }

        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(backButton)
            $0.leading.equalTo(backButton.snp.trailing).offset(8)
        }

        infoButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.leading.equalTo(titleLabel.snp.trailing).offset(6)
            $0.size.equalTo(20)
        }

        cardView.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.greaterThanOrEqualTo(448)
        }

        helperContainerView.snp.makeConstraints {
            $0.top.equalTo(cardView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        helperIconView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(12)
            $0.size.equalTo(20)
        }

        helperLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(12)
            $0.leading.equalTo(helperIconView.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().inset(12)
        }

        historyTitleLabel.snp.makeConstraints {
            $0.top.equalTo(helperContainerView.snp.bottom).offset(28)
            $0.leading.equalToSuperview().offset(16)
        }

        historyContainerView.snp.makeConstraints {
            $0.top.equalTo(historyTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(32)
        }

        historyStackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(12)
            $0.leading.trailing.equalToSuperview()
        }

        historyTitleLabel.isHidden = true
        historyContainerView.isHidden = true
    }

    func configureContent() {
        cardView.configure(
            with: profileItem.profile,
            collectionCount: profileItem.collectionCount,
            tastingCount: profileItem.tastingCount
        )
        helperLabel.text = helperText(for: profileItem.profile)
    }

    func helperText(for profile: UserTasteProfile) -> String {
        switch profile.stage {
        case .onboardingOnly:
            return AppStrings.DomainDisplay.TasteProfile.needsCollectionOrRecord
        case .onboardingCollection:
            return AppStrings.DomainDisplay.TasteProfile.needsTastingRecord
        case .earlyTasting, .heavyTasting:
            return "향수를 등록하거나 시향 기록을 남기면 취향이 계속 업데이트돼요"
        }
    }

    // MARK: - History

    /// 현재 프로필을 Firestore에 기록한 뒤 히스토리 목록을 가져와 표시
    func recordAndFetchHistory() {
        // 1차: 현재 프로필 기록 + 히스토리 반환
        userTasteRepository.recordTasteProfileHistoryIfNeeded(
            profile: profileItem.profile,
            collectionCount: profileItem.collectionCount,
            tastingCount: profileItem.tastingCount
        )
        .observe(on: MainScheduler.instance)
        .subscribe(onSuccess: { [weak self] entries in
            guard let self else { return }
            if !entries.isEmpty {
                self.populateHistory(entries: entries)
            } else {
                // 기록은 됐지만 빈 배열 → 직접 fetch
                self.fallbackFetchHistory()
            }
        }, onFailure: { [weak self] error in
            print("[TasteProfile] 히스토리 기록 실패, fetch 시도:", error)
            self?.fallbackFetchHistory()
        })
        .disposed(by: disposeBag)
    }

    /// recordTasteProfileHistoryIfNeeded 실패 시 단순 fetch fallback
    func fallbackFetchHistory() {
        userTasteRepository.fetchTasteProfileHistory()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] entries in
                guard let self, !entries.isEmpty else { return }
                self.populateHistory(entries: entries)
            }, onFailure: { error in
                print("[TasteProfile] 히스토리 fetch도 실패:", error)
            })
            .disposed(by: disposeBag)
    }

    func populateHistory(entries: [TasteProfileHistoryEntry]) {
        historyTitleLabel.isHidden = false
        historyContainerView.isHidden = false

        // 최신순 정렬
        let sorted = entries.sorted {
            ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
        }
        currentEntryId = sorted.first?.id
        cachedEntries = sorted  // entry 탭 시 조회를 위해 캐싱

        // 기존 뷰 초기화
        historyStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        sorted.enumerated().forEach { index, entry in
            let isCurrent = entry.id == currentEntryId
            let row = makeHistoryRow(entry: entry, isCurrent: isCurrent)
            historyStackView.addArrangedSubview(row)

            // 구분선 (마지막 항목 제외)
            if index < sorted.count - 1 {
                let divider = UIView()
                divider.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1)
                historyStackView.addArrangedSubview(divider)
                divider.snp.makeConstraints { $0.height.equalTo(1) }
            }
        }
    }

    func makeHistoryRow(entry: TasteProfileHistoryEntry, isCurrent: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground

        // 그라데이션 썸네일 (56pt, cornerRadius 14)
        let iconView = TasteProfileGradientIconView()
        iconView.configure(title: entry.title, fallbackFamilies: entry.families)
        iconView.layer.cornerRadius = 11
        iconView.layer.cornerCurve = .continuous
        iconView.clipsToBounds = true

        // 취향명
        let nameLabel = UILabel().then {
            $0.text = entry.title
            $0.font = UIFont(name: "Pretendard-Medium", size: 16) ?? .systemFont(ofSize: 16, weight: .medium)
            $0.textColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
            $0.numberOfLines = 1
        }

        // 중심 계열 (영어 family명 → 한국어 변환)
        let koreanFamilies = entry.families.prefix(2).map { TasteProfileViewController.koreanFamilyName($0) }
        let familiesText = koreanFamilies.joined(separator: " · ")
        let subtitleLabel = UILabel().then {
            $0.text = familiesText.isEmpty ? "" : familiesText + " 중심"
            $0.font = UIFont(name: "Pretendard-Medium", size: 12) ?? .systemFont(ofSize: 12, weight: .medium)
            $0.textColor = UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)
            $0.numberOfLines = 1
        }

        // 적용중 뱃지 (Gardenia/300 배경, Gardenia/800 텍스트, H:24, radius:8, 좌우 8pt 패딩)
        let badgeContainerView = UIView().then {
            $0.backgroundColor = UIColor(red: 0.96, green: 0.93, blue: 0.89, alpha: 1) // Gardenia/300
            $0.layer.cornerRadius = 8
            $0.layer.cornerCurve = .continuous
            $0.clipsToBounds = true
            $0.isHidden = !isCurrent
        }
        let badgeInnerLabel = UILabel().then {
            $0.text = "적용중"
            $0.font = UIFont(name: "Pretendard-Medium", size: 13) ?? .systemFont(ofSize: 13, weight: .medium)
            $0.textColor = UIColor(red: 0.52, green: 0.50, blue: 0.48, alpha: 1)
        }
        badgeContainerView.addSubview(badgeInnerLabel)
        badgeInnerLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(8)
        }

        [iconView, nameLabel, subtitleLabel, badgeContainerView].forEach { container.addSubview($0) }

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(4)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }

        badgeContainerView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(4)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(24)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.leading.equalTo(iconView.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(isCurrent ? badgeContainerView.snp.leading : container.snp.trailing).offset(-4)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.equalTo(nameLabel)
            $0.trailing.lessThanOrEqualTo(container.snp.trailing).offset(-4)
            $0.bottom.equalToSuperview().inset(14)
        }

        // 현재 적용 중이 아닌 항목만 탭 가능
        if !isCurrent {
            let tap = UITapGestureRecognizer(target: self, action: #selector(historyRowTapped(_:)))
            container.addGestureRecognizer(tap)
            container.accessibilityIdentifier = entry.id
            container.isUserInteractionEnabled = true
        }

        return container
    }

    @objc func historyRowTapped(_ gesture: UITapGestureRecognizer) {
        guard let container = gesture.view,
              let entryId = container.accessibilityIdentifier else { return }

        // 해당 entry 찾기
        guard let entry = findEntry(byId: entryId) else { return }

        applyProfile(entry: entry)
    }

    private func findEntry(byId id: String) -> TasteProfileHistoryEntry? {
        // historyStackView의 arranged subviews에서 entry 찾기
        for view in historyStackView.arrangedSubviews {
            if view.accessibilityIdentifier == id {
                // entry 정보는 accessibilityLabel에 저장
                // 대신 entry를 캐싱하는 방식 사용
            }
        }
        return cachedEntries.first { $0.id == id }
    }

    func applyProfile(entry: TasteProfileHistoryEntry) {
        // 로딩 인디케이터
        let alert = UIAlertController(title: nil, message: "취향 프로필을 변경하는 중...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true)

        Task {
            do {
                try await userTasteRepository.applyHistoricalProfile(entry)

                // 홈 화면과 마이페이지에 프로필 변경 알림
                NotificationCenter.default.post(
                    name: .tasteProfileDidChange,
                    object: nil,
                    userInfo: [
                        "title": entry.title,
                        "families": entry.families
                    ]
                )

                await MainActor.run {
                    alert.dismiss(animated: true) { [weak self] in
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    alert.dismiss(animated: true)
                    print("[TasteProfile] 프로필 적용 실패:", error)
                }
            }
        }
    }
}
