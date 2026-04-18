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

final class HomeViewController: UIViewController {

    private let viewModel: HomeViewModel
    private let disposeBag = DisposeBag()
    private var recommendations: [HomePerfumeItem] = []
    private var currentProfileItem: HomeViewModel.HomeProfileItem?

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
        l.text = "오늘의 추천 향수"
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

    private let guideLabel: UILabel = {
        let l = UILabel()
        l.text = "추천은 취향 분석과 시향 기록, 등록한 향수를 기반으로 계속 업데이트돼요."
        l.font = .systemFont(ofSize: 11)
        l.textColor = .quaternaryLabel
        l.numberOfLines = 0
        return l
    }()

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }
}

    // MARK: - UI Setup

private extension HomeViewController {

    func setupUI() {
        view.backgroundColor = .systemBackground

        recommendationCollectionView.delegate = self
        recommendationCollectionView.dataSource = self
        recommendationCollectionView.register(
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
            $0.height.equalTo(268)
        }
        recommendationCollectionView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(14)
            $0.leading.trailing.equalToSuperview()
        }

        guideLabel.snp.makeConstraints {
            $0.top.equalTo(cardsBackgroundView.snp.bottom).offset(12)
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
            perfumeSelect: recommendationCollectionView.rx.itemSelected.asObservable()
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
            }
            .disposed(by: disposeBag)

            // 라우팅
        output.route
            .emit(with: self) { owner, route in owner.handleRoute(route) }
            .disposed(by: disposeBag)

        searchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                let alert = UIAlertController(title: "검색", message: "검색 화면 연결 예정이에요.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
    }

    func handleRoute(_ route: HomeRoute) {
        switch route {
            case .perfumeRegister:   presentAlert("향수 등록 화면으로 연결할 수 있어요.")
            case .tastingNoteWrite:  presentAlert("시향기 작성 화면으로 연결할 수 있어요.")
            case .tasteReport:       presentAlert("취향 리포트 화면으로 연결할 수 있어요.")
            case .perfumeDetail(let id):
                if id.hasPrefix("local-") { presentAlert("현재 카드는 샘플 데이터예요."); return }
                let detailViewController = PerfumeDetailSceneFactory.makeViewController(perfumeId: id)
                navigationController?.pushViewController(detailViewController, animated: true)
        }
    }

    func presentAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
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
}

    // MARK: - CollectionView

extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        recommendations.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomePerfumeCardCell.reuseIdentifier, for: indexPath
        ) as? HomePerfumeCardCell else { return UICollectionViewCell() }
        cell.configure(with: recommendations[indexPath.item])
        return cell
    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 148, height: 228)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
}
