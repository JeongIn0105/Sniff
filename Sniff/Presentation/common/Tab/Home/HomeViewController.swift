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

    private let viewModel = HomeViewModel()
    private let disposeBag = DisposeBag()

    private var quickActions: [HomeQuickAction] = []
    private var recommendations: [HomePerfumeItem] = []

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "킁킁"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = .label
        return button
    }()

    private let bannerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        view.layer.cornerRadius = 16
        return view
    }()

    private let bannerTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let bannerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let quickActionCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    private let recommendationTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 추천 향수"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let recommendationCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }
}

private extension HomeViewController {

    func configureUI() {
        view.backgroundColor = .systemBackground

        quickActionCollectionView.delegate = self
        quickActionCollectionView.dataSource = self
        recommendationCollectionView.delegate = self
        recommendationCollectionView.dataSource = self

        quickActionCollectionView.register(
            HomeQuickActionCell.self,
            forCellWithReuseIdentifier: HomeQuickActionCell.reuseIdentifier
        )

        recommendationCollectionView.register(
            HomePerfumeCardCell.self,
            forCellWithReuseIdentifier: HomePerfumeCardCell.reuseIdentifier
        )

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            titleLabel,
            searchButton,
            bannerView,
            quickActionCollectionView,
            recommendationTitleLabel,
            recommendationCollectionView
        ].forEach { contentView.addSubview($0) }

        [bannerTitleLabel, bannerSubtitleLabel].forEach { bannerView.addSubview($0) }

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(20)
        }

        searchButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(20)
            make.size.equalTo(24)
        }

        bannerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(18)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(138)
        }

        bannerTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.equalTo(bannerSubtitleLabel.snp.top).offset(-6)
        }

        bannerSubtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().inset(22)
        }

        quickActionCollectionView.snp.makeConstraints { make in
            make.top.equalTo(bannerView.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(84)
        }

        recommendationTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(quickActionCollectionView.snp.bottom).offset(22)
            make.leading.equalToSuperview().offset(20)
        }

        recommendationCollectionView.snp.makeConstraints { make in
            make.top.equalTo(recommendationTitleLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(214)
            make.bottom.equalToSuperview().inset(20)
        }
    }

    func bind() {
        let perfumeRegisterTap = PublishRelay<Void>()
        let tastingNoteTap = PublishRelay<Void>()
        let reportTap = PublishRelay<Void>()

        let input = HomeViewModel.Input(
            viewDidLoad: Observable.just(()),
            perfumeRegisterTap: perfumeRegisterTap.asObservable(),
            tastingNoteTap: tastingNoteTap.asObservable(),
            reportTap: reportTap.asObservable(),
            perfumeSelect: recommendationCollectionView.rx.itemSelected.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.bannerTitle
            .drive(bannerTitleLabel.rx.text)
            .disposed(by: disposeBag)

        output.bannerSubtitle
            .drive(bannerSubtitleLabel.rx.text)
            .disposed(by: disposeBag)

        output.quickActions
            .drive(with: self) { owner, actions in
                owner.quickActions = actions
                owner.quickActionCollectionView.reloadData()
            }
            .disposed(by: disposeBag)

        output.recommendations
            .drive(with: self) { owner, items in
                owner.recommendations = items
                owner.recommendationCollectionView.reloadData()
            }
            .disposed(by: disposeBag)

        output.route
            .emit(with: self) { owner, route in
                owner.handleRoute(route)
            }
            .disposed(by: disposeBag)

        quickActionCollectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self, self.quickActions.indices.contains(indexPath.item) else { return }

                switch self.quickActions[indexPath.item].type {
                    case .perfumeRegister:
                        perfumeRegisterTap.accept(())
                    case .tastingNote:
                        tastingNoteTap.accept(())
                    case .report:
                        reportTap.accept(())
                }
            })
            .disposed(by: disposeBag)

        searchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                let alert = UIAlertController(
                    title: "검색",
                    message: "검색 화면 연결이 필요한 상태예요.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
    }

    func handleRoute(_ route: HomeRoute) {
        switch route {
            case .perfumeRegister:
                presentAlert(message: "향수 등록 화면으로 연결할 수 있어요.")
            case .tastingNoteWrite:
                presentAlert(message: "시향기 작성 화면으로 연결할 수 있어요.")
            case .tasteReport:
                presentAlert(message: "취향 리포트 화면으로 연결할 수 있어요.")
            case .perfumeDetail(let id):
                let detailViewController = PerfumeDetailViewController(perfumeId: "\(id)")
                navigationController?.pushViewController(detailViewController, animated: true)
        }
    }

    func presentAlert(message: String) {
        let alert = UIAlertController(title: "이동", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension HomeViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == quickActionCollectionView {
            return quickActions.count
        }
        return recommendations.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if collectionView == quickActionCollectionView {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HomeQuickActionCell.reuseIdentifier,
                for: indexPath
            ) as? HomeQuickActionCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: quickActions[indexPath.item])
            return cell
        }

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomePerfumeCardCell.reuseIdentifier,
            for: indexPath
        ) as? HomePerfumeCardCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: recommendations[indexPath.item])
        return cell
    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if collectionView == quickActionCollectionView {
            return CGSize(width: 84, height: 80)
        }
        return CGSize(width: 94, height: 194)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
}
