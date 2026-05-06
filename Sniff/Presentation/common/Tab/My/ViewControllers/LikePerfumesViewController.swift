//
//  LikePerfumesViewController.swift
//  Sniff
//
//  Created by Codex on 2026.04.18.
//

import Combine
import RxSwift
import SnapKit
import SwiftUI
import UIKit

final class LikePerfumesViewController: UIViewController {
    private let collectionRepository: CollectionRepositoryType
    private let disposeBag = DisposeBag()
    private let state = LikePerfumesScreenState()
    private var hostingController: UIHostingController<LikePerfumesScreenView>?

    init(collectionRepository: CollectionRepositoryType) {
        self.collectionRepository = collectionRepository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHostingView()
        loadItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        state.showsBackButton = (navigationController?.viewControllers.count ?? 0) > 1
        loadItems()
    }
}

private extension LikePerfumesViewController {
    func setupHostingView() {
        view.backgroundColor = .systemBackground

        let rootView = LikePerfumesScreenView(
            state: state,
            onBack: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onPerfumeTap: { [weak self] perfume in
                let detailViewController = PerfumeDetailSceneFactory.makeViewController(perfume: perfume)
                self?.navigationController?.pushViewController(detailViewController, animated: true)
            },
            onLikeTap: { [weak self] item in
                self?.deleteItem(id: item.id)
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

    func loadItems() {
        state.isLoading = true
        collectionRepository.fetchLikedPerfumes()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                self?.state.items = items.sorted {
                    ($0.likedAt ?? .distantPast) > ($1.likedAt ?? .distantPast)
                }
                self?.state.isLoading = false
            }, onFailure: { [weak self] _ in
                self?.state.items = []
                self?.state.isLoading = false
            })
            .disposed(by: disposeBag)
    }

    func deleteItem(id: String) {
        let previousItems = state.items
        state.items = state.items.filter { $0.id != id }

        collectionRepository.deleteLikedPerfume(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: {
                NotificationCenter.default.postPerfumeCollectionDidChange(scope: .liked)
            }, onError: { [weak self] _ in
                self?.state.items = previousItems
            })
            .disposed(by: disposeBag)
    }
}

private final class LikePerfumesScreenState: ObservableObject {
    @Published var items: [LikedPerfume] = []
    @Published var isLoading = false
    @Published var showsBackButton = false
}

private struct LikePerfumesScreenView: View {
    @ObservedObject var state: LikePerfumesScreenState
    let onBack: () -> Void
    let onPerfumeTap: (Perfume) -> Void
    let onLikeTap: (LikedPerfume) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            if state.isLoading && state.items.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if state.items.isEmpty {
                emptyState
            } else {
                perfumeGrid
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if state.showsBackButton {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }

                Text(AppStrings.DomainDisplay.LikePerfumes.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)

                Spacer(minLength: 0)
            }

            Text(AppStrings.DomainDisplay.LikePerfumes.count(state.items.count))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var perfumeGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, alignment: .center, spacing: 30) {
                ForEach(state.items) { item in
                    perfumeCard(item)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "heart")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(Color(.systemGray3))

            Text(AppStrings.DomainDisplay.LikePerfumes.empty)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    private func perfumeCard(_ item: LikedPerfume) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Button {
                onPerfumeTap(item.toPerfume())
            } label: {
                PerfumeGridCardView(
                    imageURL: item.imageURL,
                    brand: item.brand,
                    name: item.name,
                    accords: PerfumePresentationSupport.previewAccords(
                        mainAccords: item.mainAccords,
                        fallback: item.scentFamilies
                    ),
                    isLiked: true,
                    style: .grid,
                    cardWidth: nil,
                    showsHeartIcon: false,
                    hasTastingRecord: false,
                    textBottomAccessory: nil,
                    textBottomAccessoryHeight: 0,
                    usesFixedTextBlockHeight: nil
                )
            }
            .buttonStyle(.plain)

            PerfumeCardHeartButton(
                isLiked: true,
                style: .grid,
                action: { onLikeTap(item) }
            )
            .padding(.trailing, PerfumeCardStyle.grid.likeIconInset)
            .padding(.bottom, PerfumeCardStyle.grid.likeIconInset + (PerfumeCardStyle.grid.textBlockHeight ?? 0) + PerfumeCardStyle.grid.contentTopSpacing)
        }
    }
}
