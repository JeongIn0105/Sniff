//
//  View.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

<<<<<<< HEAD
import Foundation
=======
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher

final class PerfumeDetailViewController: UIViewController {

    private let viewModel: PerfumeDetailViewModel
    private let disposeBag = DisposeBag()

    init(perfumeId: String) {
        self.viewModel = PerfumeDetailViewModel(perfumeId: perfumeId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

        // MARK: - UI

    private let imageView = UIImageView()

    private let brandLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 2
        return label
    }()

    private let notesLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }
}

    // MARK: - UI
private extension PerfumeDetailViewController {

    func setupUI() {
        view.backgroundColor = .systemBackground
        title = "향수 상세"

        view.addSubview(imageView)
        view.addSubview(brandLabel)
        view.addSubview(nameLabel)
        view.addSubview(notesLabel)

        imageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.centerX.equalToSuperview()
            make.size.equalTo(150)
        }

        brandLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(brandLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        notesLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }
}

    // MARK: - Bind
private extension PerfumeDetailViewController {

    func bind() {
        let input = PerfumeDetailViewModel.Input(
            viewDidLoad: Observable.just(())
        )

        let output = viewModel.transform(input: input)

        output.perfumeName
            .drive(nameLabel.rx.text)
            .disposed(by: disposeBag)

        output.brandName
            .drive(brandLabel.rx.text)
            .disposed(by: disposeBag)

        output.notesText
            .drive(notesLabel.rx.text)
            .disposed(by: disposeBag)

        output.imageURL
            .drive(onNext: { [weak self] urlString in
                guard let self else { return }

                if let urlString,
                   let url = URL(string: urlString) {

                    self.imageView.kf.setImage(
                        with: url,
                        placeholder: UIImage(systemName: "photo")
                    )
                }
            })
            .disposed(by: disposeBag)
    }
}
>>>>>>> origin/main
