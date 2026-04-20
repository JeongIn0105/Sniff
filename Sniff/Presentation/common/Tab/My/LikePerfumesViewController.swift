//
//  LikePerfumesViewController.swift
//  Sniff
//
//  Created by Codex on 2026.04.18.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then

final class LikePerfumesViewController: UIViewController {

    private let collectionRepository: CollectionRepositoryType
    private let disposeBag = DisposeBag()
    private var items: [CollectedPerfume] = []

    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .label
    }

    private let titleLabel = UILabel().then {
        $0.text = "LIKE 향수"
        $0.font = .systemFont(ofSize: 24, weight: .bold)
        $0.textColor = .label
    }

    private let countLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .secondaryLabel
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 16
        let itemWidth = (UIScreen.main.bounds.width - spacing * 3) / 2
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth + 70)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 16, left: spacing, bottom: 16, right: spacing)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .systemBackground
        view.register(PerfumeGridCell.self, forCellWithReuseIdentifier: PerfumeGridCell.identifier)
        return view
    }()

    private let emptyLabel = UILabel().then {
        $0.text = "등록된 LIKE 향수가 없어요"
        $0.font = .systemFont(ofSize: 15)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.isHidden = true
    }

    init(collectionRepository: CollectionRepositoryType = CollectionRepository()) {
        self.collectionRepository = collectionRepository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        loadItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        backButton.isHidden = (navigationController?.viewControllers.count ?? 0) <= 1
        loadItems()
    }

    private func setupUI() {
        collectionView.delegate = self
        collectionView.dataSource = self

        [backButton, titleLabel, countLabel, collectionView, emptyLabel].forEach {
            view.addSubview($0)
        }

        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(28)
        }

        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(backButton)
            $0.centerX.equalToSuperview()
        }

        countLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(20)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(countLabel.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func loadItems() {
        collectionRepository.fetchCollection()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                self?.items = items.sorted {
                    ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
                }
                self?.countLabel.text = "LIKE 향수 \(items.count)개"
                self?.emptyLabel.isHidden = !items.isEmpty
                self?.collectionView.reloadData()
            }, onFailure: { [weak self] _ in
                self?.items = []
                self?.countLabel.text = "LIKE 향수 0개"
                self?.emptyLabel.isHidden = false
                self?.collectionView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}

extension LikePerfumesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PerfumeGridCell.identifier,
            for: indexPath
        ) as! PerfumeGridCell
        let item = items[indexPath.item]
        cell.configure(with: item.toPerfume(), isLiked: true)
        cell.wishlistButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.deleteItem(id: item.id)
            })
            .disposed(by: cell.disposeBag)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let perfume = items[indexPath.item].toPerfume()
        let detailViewController = PerfumeDetailSceneFactory.makeViewController(perfume: perfume)
        navigationController?.pushViewController(detailViewController, animated: true)
    }

    private func deleteItem(id: String) {
        collectionRepository.deleteCollectedPerfume(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.items.removeAll { $0.id == id }
                self?.countLabel.text = "LIKE 향수 \(self?.items.count ?? 0)개"
                self?.emptyLabel.isHidden = !(self?.items.isEmpty ?? true)
                self?.collectionView.reloadData()
            }, onError: { _ in })
            .disposed(by: disposeBag)
    }
}
