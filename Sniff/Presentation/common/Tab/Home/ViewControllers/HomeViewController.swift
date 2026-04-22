//
//  HomeViewController.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//


import UIKit
import SnapKit
import RxSwift
import RxCocoa
import SwiftUI

final class HomeViewController: UIViewController {

    private let viewModel: HomeViewModel
    private let collectionRepository: CollectionRepositoryType
    private let disposeBag = DisposeBag()
    private var recommendations: [HomePerfumeItem] = []
    private var currentProfileItem: HomeViewModel.HomeProfileItem?
    private var likedPerfumeIDs = Set<String>()

        // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "킁킁"
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .label
        return l
    }()

    private let searchButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        b.tintColor = .label
        return b
    }()

        // 취향 프로필 entry 카드
    private let profileEntryCard: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 0.5
        v.layer.borderColor = UIColor.separator.withAlphaComponent(0.25).cgColor
        return v
    }()

    private let profileIconView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 11
        return v
    }()

    private let profileIconLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18)
        l.textAlignment = .center
        l.text = "✨"
        return l
    }()

    private let profileCategoryLabel: UILabel = {
        let l = UILabel()
        l.text = "취향 프로필"
        l.font = .systemFont(ofSize: 10, weight: .medium)
        l.textColor = .tertiaryLabel
        return l
    }()

    private let profileNameLabel: UILabel = {
        let l = UILabel()
        l.text = "분석 중..."
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .label
        return l
    }()

    private let profileChevron: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let recommendationTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "베스트"
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = .label
        return l
    }()

        // 카드 바깥 대비 배경 — 카드들이 더 잘 구분되게
    private let cardsBackgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1)
        v.layer.cornerRadius = 20
        return v
    }()

    private let recommendationCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()

    private let moreRecommendationTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "추천 향수"
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = .label
        return l
    }()

    private let moreRecommendationCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 12
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.isScrollEnabled = false
        return cv
    }()

    private var moreRecommendationHeightConstraint: Constraint?

    private let guideLabel: UILabel = {
        let l = UILabel()
        l.text = "추천은 취향 분석과 시향 기록, 등록한 향수를 기반으로 계속 업데이트돼요."
        l.font = .systemFont(ofSize: 11)
        l.textColor = .quaternaryLabel
        l.numberOfLines = 0
        return l
    }()

    init(
        viewModel: HomeViewModel,
        collectionRepository: CollectionRepositoryType
    ) {
        self.viewModel = viewModel
        self.collectionRepository = collectionRepository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadLikedPerfumes()
    }
}

    // MARK: - UI Setup

private extension HomeViewController {

    func setupUI() {
        view.backgroundColor = .systemBackground

        recommendationCollectionView.delegate = self
        recommendationCollectionView.dataSource = self
        moreRecommendationCollectionView.delegate = self
        moreRecommendationCollectionView.dataSource = self
        recommendationCollectionView.register(
            HomePerfumeCardCell.self,
            forCellWithReuseIdentifier: HomePerfumeCardCell.reuseIdentifier
        )
        moreRecommendationCollectionView.register(
            HomePerfumeCardCell.self,
            forCellWithReuseIdentifier: HomePerfumeCardCell.reuseIdentifier
        )

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            titleLabel, searchButton,
            profileEntryCard,
            recommendationTitleLabel,
            cardsBackgroundView,
            moreRecommendationTitleLabel,
            moreRecommendationCollectionView,
            guideLabel
        ].forEach { contentView.addSubview($0) }

        cardsBackgroundView.addSubview(recommendationCollectionView)

        profileEntryCard.addSubview(profileIconView)
        profileIconView.addSubview(profileIconLabel)
        profileEntryCard.addSubview(profileCategoryLabel)
        profileEntryCard.addSubview(profileNameLabel)
        profileEntryCard.addSubview(profileChevron)

        profileEntryCard.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(profileCardTapped))
        )
        profileEntryCard.isUserInteractionEnabled = true

        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(20)
        }
        searchButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(20)
            $0.size.equalTo(28)
        }

            // 취향 프로필 entry
        profileEntryCard.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(64)
        }
        profileIconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(38)
        }
        profileIconLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
        profileCategoryLabel.snp.makeConstraints {
            $0.leading.equalTo(profileIconView.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(13)
        }
        profileNameLabel.snp.makeConstraints {
            $0.leading.equalTo(profileIconView.snp.trailing).offset(12)
            $0.top.equalTo(profileCategoryLabel.snp.bottom).offset(2)
        }
        profileChevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(14)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(CGSize(width: 8, height: 14))
        }

            // 섹션 타이틀
        recommendationTitleLabel.snp.makeConstraints {
            $0.top.equalTo(profileEntryCard.snp.bottom).offset(28)
            $0.leading.equalToSuperview().offset(20)
        }

            // 카드 배경 박스 — 위아래 패딩 주어 카드가 배경 안에 떠있는 느낌
        cardsBackgroundView.snp.makeConstraints {
            $0.top.equalTo(recommendationTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(0)
            $0.height.equalTo(332)
        }
        recommendationCollectionView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(16)
            $0.leading.trailing.equalToSuperview()
        }

        moreRecommendationTitleLabel.snp.makeConstraints {
            $0.top.equalTo(cardsBackgroundView.snp.bottom).offset(28)
            $0.leading.equalToSuperview().offset(20)
        }
        moreRecommendationCollectionView.snp.makeConstraints {
            $0.top.equalTo(moreRecommendationTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            self.moreRecommendationHeightConstraint = $0.height.equalTo(0).constraint
        }

        guideLabel.snp.makeConstraints {
            $0.top.equalTo(moreRecommendationCollectionView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
        }
    }

        // 취향 프로필 카드 탭 → 취향 프로필 상세 화면 이동
    @objc func profileCardTapped() {
        guard let item = currentProfileItem else { return }

        let profileVC = TasteProfileViewController(profileItem: item)
        navigationController?.pushViewController(profileVC, animated: true)
    }
}

    // MARK: - Bind

private extension HomeViewController {

    func bind() {
        let input = HomeViewModel.Input(
            viewDidLoad: Observable.just(()),
            perfumeRegisterTap: .never(),
            tastingNoteTap: .never(),
            reportTap: .never(),
            perfumeSelect: .never()
        )

        let output = viewModel.transform(input: input)

            // 취향 프로필 entry 카드
        output.profile
            .drive(with: self) { owner, item in
                guard let item else { return }
                owner.currentProfileItem = item
                let profile = item.profile
                owner.profileNameLabel.text = profile.primaryProfileName
                owner.profileIconLabel.text = Self.profileEmoji(for: profile.primaryProfileCode)
                owner.profileIconView.backgroundColor = Self.profileIconBg(for: profile.primaryProfileCode)
            }
            .disposed(by: disposeBag)

            // 추천 향수
        output.recommendations
            .drive(with: self) { owner, items in
                owner.recommendations = items
                owner.recommendationCollectionView.reloadData()
                owner.moreRecommendationCollectionView.reloadData()
                owner.updateMoreRecommendationHeight()
            }
            .disposed(by: disposeBag)

            // 라우팅
        output.route
            .emit(with: self) { owner, route in owner.handleRoute(route) }
            .disposed(by: disposeBag)

        searchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                let searchViewController = SearchSceneFactory.makeSearchViewController()
                self?.navigationController?.pushViewController(searchViewController, animated: true)
            })
            .disposed(by: disposeBag)
    }

    func handleRoute(_ route: HomeRoute) {
        switch route {
            case .perfumeRegister:   presentAlert("향수 등록 화면으로 연결할 수 있어요.")
            case .tastingNoteWrite:  presentAlert("시향기 작성 화면으로 연결할 수 있어요.")
            case .tasteReport:       presentAlert("취향 리포트 화면으로 연결할 수 있어요.")
            case .perfumeDetail(let perfume):
                if perfume.id.hasPrefix("local-") { presentAlert("현재 카드는 샘플 데이터예요."); return }
                let detailViewController = PerfumeDetailSceneFactory.makeViewController(perfume: perfume)
                navigationController?.pushViewController(detailViewController, animated: true)
        }
    }

    func presentAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    func loadLikedPerfumes() {
        collectionRepository.fetchLikedPerfumes()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                self?.likedPerfumeIDs = Set(items.map(\.id))
                self?.recommendationCollectionView.reloadData()
                self?.moreRecommendationCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    func saveLike(for item: HomePerfumeItem) {
        let perfume = Perfume(
            id: item.id,
            name: item.perfumeName,
            brand: item.brandName,
            imageUrl: item.imageURL,
            rawMainAccords: item.parsedAccords,
            mainAccords: item.parsedAccords,
            topNotes: nil,
            middleNotes: nil,
            baseNotes: nil,
            concentration: nil,
            gender: nil,
            season: nil,
            situation: nil,
            longevity: nil,
            sillage: nil
        )

        collectionRepository.saveLikedPerfume(perfume)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.likedPerfumeIDs.insert(item.id)
                self?.recommendationCollectionView.reloadData()
                self?.moreRecommendationCollectionView.reloadData()
                self?.presentLikeSavedAlert(perfumeName: item.perfumeName)
            })
            .disposed(by: disposeBag)
    }

    func deleteLike(id: String) {
        collectionRepository.deleteLikedPerfume(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.likedPerfumeIDs.remove(id)
                self?.recommendationCollectionView.reloadData()
                self?.moreRecommendationCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    func presentLikeSavedAlert(perfumeName: String) {
        let alert = UIAlertController(
            title: nil,
            message: "\(PerfumePresentationSupport.displayPerfumeName(perfumeName))을 LIKE 향수에 저장했어요.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        alert.addAction(UIAlertAction(title: "LIKE 향수 보기", style: .default) { [weak self] _ in
            let likedView = TastingNoteSceneFactory.makeLikedPerfumeListView()
            let hostingController = UIHostingController(rootView: likedView)
            self?.navigationController?.pushViewController(hostingController, animated: true)
        })

        present(alert, animated: true)
    }

    static func profileEmoji(for code: String) -> String {
        switch code {
            case "P1": return "💧"; case "P2": return "🍋"
            case "P3": return "🌸"; case "P4": return "🌹"
            case "P5": return "🪵"; case "P6": return "🌿"
            case "P7": return "🌙"; case "P8": return "🔥"
            default:   return "✨"
        }
    }

    static func profileIconBg(for code: String) -> UIColor {
        switch code {
            case "P1", "P2": return UIColor(red: 0.89, green: 0.96, blue: 0.93, alpha: 1)
            case "P3", "P4": return UIColor(red: 0.98, green: 0.92, blue: 0.94, alpha: 1)
            case "P5", "P6": return UIColor(red: 0.98, green: 0.95, blue: 0.87, alpha: 1)
            case "P7", "P8": return UIColor(red: 0.93, green: 0.93, blue: 0.99, alpha: 1)
            default:         return UIColor(red: 0.95, green: 0.93, blue: 0.91, alpha: 1)
        }
    }

    var bestRecommendations: [HomePerfumeItem] {
        Array(recommendations.prefix(3))
    }

    var moreRecommendations: [HomePerfumeItem] {
        Array(recommendations.dropFirst(3).prefix(10))
    }

    func recommendationItem(for collectionView: UICollectionView, indexPath: IndexPath) -> HomePerfumeItem? {
        let source = collectionView === recommendationCollectionView ? bestRecommendations : moreRecommendations
        guard source.indices.contains(indexPath.item) else { return nil }
        return source[indexPath.item]
    }

    func updateMoreRecommendationHeight() {
        let count = moreRecommendations.count
        guard count > 0 else {
            moreRecommendationHeightConstraint?.update(offset: 0)
            return
        }

        let rows = ceil(CGFloat(count) / 2)
        let height = rows * 280 + max(0, rows - 1) * 16
        moreRecommendationHeightConstraint?.update(offset: height)
    }
}

    // MARK: - CollectionView

extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView === recommendationCollectionView ? bestRecommendations.count : moreRecommendations.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomePerfumeCardCell.reuseIdentifier, for: indexPath
        ) as? HomePerfumeCardCell else { return UICollectionViewCell() }
        guard let item = recommendationItem(for: collectionView, indexPath: indexPath) else {
            return UICollectionViewCell()
        }
        cell.configure(with: item, isLiked: likedPerfumeIDs.contains(item.id))
        cell.wishlistButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                if self.likedPerfumeIDs.contains(item.id) {
                    self.deleteLike(id: item.id)
                } else {
                    self.saveLike(for: item)
                }
            })
            .disposed(by: cell.disposeBag)
        return cell
    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === recommendationCollectionView {
            return CGSize(width: 188, height: 284)
        }

        let width = floor((collectionView.bounds.width - 12) / 2)
        return CGSize(width: width, height: 280)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView === recommendationCollectionView {
            return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = recommendationItem(for: collectionView, indexPath: indexPath) else { return }
        if item.id.hasPrefix("local-") {
            presentAlert("현재 카드는 샘플 데이터예요.")
            return
        }
        let detailViewController = PerfumeDetailSceneFactory.makeViewController(perfume: item.perfume)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
