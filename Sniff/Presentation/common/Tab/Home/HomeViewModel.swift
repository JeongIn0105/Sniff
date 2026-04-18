//
//  HomeViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

final class HomeViewModel {

    struct Input {
        let viewDidLoad: Observable<Void>
        let perfumeRegisterTap: Observable<Void>
        let tastingNoteTap: Observable<Void>
        let reportTap: Observable<Void>
        let perfumeSelect: Observable<IndexPath>
    }

    struct Output {
        let banner: Driver<HomeTasteBannerItem>
        let quickActions: Driver<[HomeQuickAction]>
        let recommendations: Driver<[HomePerfumeItem]>
        let profile: Driver<HomeProfileItem?>   // 취향 프로필 카드용
        let route: Signal<HomeRoute>
    }

        // MARK: - 취향 프로필 카드에 필요한 데이터 묶음
    struct HomeProfileItem {
        let profile: UserTasteProfile
        let collectionCount: Int
        let tastingCount: Int
    }

    private let disposeBag = DisposeBag()
    private let routeRelay = PublishRelay<HomeRoute>()
    private let recommendationItemsRelay = BehaviorRelay<[HomePerfumeItem]>(value: [])

    private let fetchHomeFeedUseCase: FetchHomeFeedUseCaseType
    private let recommendPerfumesUseCase: RecommendPerfumesUseCaseType

    init(
        fetchHomeFeedUseCase: FetchHomeFeedUseCaseType,
        recommendPerfumesUseCase: RecommendPerfumesUseCaseType
    ) {
        self.fetchHomeFeedUseCase = fetchHomeFeedUseCase
        self.recommendPerfumesUseCase = recommendPerfumesUseCase
    }

    func transform(input: Input) -> Output {

        let quickActions = input.viewDidLoad
            .map {
                [
                    HomeQuickAction(type: .perfumeRegister, title: "향수 등록", systemImageName: "square.stack.3d.down.right.fill"),
                    HomeQuickAction(type: .tastingNote, title: "시향기 등록", systemImageName: "square.stack.3d.down.right.fill"),
                    HomeQuickAction(type: .report, title: "취향 리포트", systemImageName: "square.stack.3d.down.right.fill")
                ]
            }
            .asDriver(onErrorJustReturn: [])

            // 세 소스를 한 번에 묶어서 share — banner / profile / recommendations 모두 여기서 파생
        let sourceData = input.viewDidLoad
            .flatMapLatest { [weak self] _ -> Observable<HomeFeedData?> in
                guard let self else { return .just(nil) }

                return self.fetchHomeFeedUseCase.execute()
                    .map(Optional.some)
                    .catchAndReturn(nil)
                    .asObservable()
            }
            .share(replay: 1, scope: .whileConnected)

        let recommendationResult = sourceData
            .flatMapLatest { [weak self] data -> Observable<RecommendationResult?> in
                guard let self, let data else {
                    return .just(nil)
                }

                return self.recommendPerfumesUseCase.execute(
                    onboarding: data.tasteAnalysis,
                    collection: data.collection,
                    tastingRecords: data.tastingRecords
                )
                .map(Optional.some)
                .catchAndReturn(nil)
                .asObservable()
            }
            .share(replay: 1, scope: .whileConnected)

        let banner = recommendationResult
            .map { [weak self] result -> HomeTasteBannerItem in
                guard let self, let result else { return Self.defaultBanner() }
                return self.makeBanner(from: result.profile)
            }
            .asDriver(onErrorJustReturn: Self.defaultBanner())

            // 취향 프로필 카드용 — profile + count 정보 함께 전달
        let profile = Observable.combineLatest(sourceData, recommendationResult)
            .map { source, result -> HomeProfileItem? in
                guard
                    let source,
                    let result = result
                else { return nil }

                return HomeProfileItem(
                    profile: result.profile,
                    collectionCount: source.collection.count,
                    tastingCount: source.tastingRecords.count
                )
            }
            .asDriver(onErrorJustReturn: nil)

        let recommendations = recommendationResult
            .map { [weak self] result -> [HomePerfumeItem] in
                guard let self, let result else {
                    self?.recommendationItemsRelay.accept([])
                    return []
                }
                let items = result.perfumes.map { self.mapToHomePerfumeItem($0) }
                self.recommendationItemsRelay.accept(items)
                return items
            }
            .asDriver(onErrorJustReturn: [])

        input.perfumeRegisterTap
            .map { HomeRoute.perfumeRegister }
            .bind(to: routeRelay)
            .disposed(by: disposeBag)

        input.tastingNoteTap
            .map { HomeRoute.tastingNoteWrite }
            .bind(to: routeRelay)
            .disposed(by: disposeBag)

        input.reportTap
            .map { HomeRoute.tasteReport }
            .bind(to: routeRelay)
            .disposed(by: disposeBag)

        input.perfumeSelect
            .withLatestFrom(recommendationItemsRelay.asObservable()) { ($0, $1) }
            .compactMap { indexPath, items -> HomeRoute? in
                guard items.indices.contains(indexPath.item) else { return nil }
                return .perfumeDetail(id: items[indexPath.item].id)
            }
            .bind(to: routeRelay)
            .disposed(by: disposeBag)

        return Output(
            banner: banner,
            quickActions: quickActions,
            recommendations: recommendations,
            profile: profile,
            route: routeRelay.asSignal()
        )
    }
}

private extension HomeViewModel {

    func mapToHomePerfumeItem(_ recommendation: RecommendedPerfume) -> HomePerfumeItem {
        let perfume = recommendation.perfume
        return HomePerfumeItem(
            id: perfume.id,
            brandName: perfume.brand,
            perfumeName: perfume.name,
            accordsText: makeAccordText(perfume),
            recommendationReason: recommendation.reason,
            imageURL: perfume.imageUrl
        )
    }

    func makeAccordText(_ perfume: Perfume) -> String {
        let accords = ScentFamilyNormalizer.canonicalNames(
            for: Array(perfume.mainAccords.prefix(2))
        ).prefix(2)
        return accords.isEmpty
        ? "• Floral  • Musk"
        : accords.map { "• \($0)" }.joined(separator: "  ")
    }

    func makeBanner(from profile: UserTasteProfile) -> HomeTasteBannerItem {
        let familyText = profile.preferredFamilies.prefix(2).joined(separator: " · ")
        let summary: String

        if !profile.safeStartingPoint.isEmpty {
            summary = profile.safeStartingPoint
        } else if !profile.analysisSummary.isEmpty {
            summary = profile.analysisSummary
        } else if !familyText.isEmpty {
            summary = "\(familyText) 계열을 중심으로 추천을 이어가고 있어요"
        } else {
            summary = "나에게 맞는 향수를 찾아가요"
        }

        return HomeTasteBannerItem(
            title: profile.primaryProfileName,
            summary: summary,
            familyText: familyText
        )
    }

    static func defaultBanner() -> HomeTasteBannerItem {
        HomeTasteBannerItem(
            title: "킁킁 서비스와 함께",
            summary: "나에게 맞는 향수를 찾아가요",
            familyText: ""
        )
    }
}
