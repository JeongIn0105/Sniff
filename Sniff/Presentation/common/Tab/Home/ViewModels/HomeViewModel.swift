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

typealias HomeFeedData = (
    tasteAnalysis: TasteAnalysisResult,
    collection: [CollectedPerfume],
    tastingRecords: [TastingRecord]
)

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
        let profile: Driver<HomeProfileItem?>
        let route: Signal<HomeRoute>
    }

    struct HomeProfileItem {
        let profile: UserTasteProfile
        let collectionCount: Int
        let tastingCount: Int
    }

    private let disposeBag = DisposeBag()
    private let routeRelay = PublishRelay<HomeRoute>()
    private let recommendationItemsRelay = BehaviorRelay<[HomePerfumeItem]>(value: [])

    private let userTasteRepository: UserTasteRepositoryType
    private let collectionRepository: CollectionRepositoryType
    private let tastingRecordRepository: TastingRecordRepositoryType
    private let recommendPerfumesUseCase: RecommendPerfumesUseCaseType

    init(
        userTasteRepository: UserTasteRepositoryType,
        collectionRepository: CollectionRepositoryType,
        tastingRecordRepository: TastingRecordRepositoryType,
        recommendPerfumesUseCase: RecommendPerfumesUseCaseType
    ) {
        self.userTasteRepository = userTasteRepository
        self.collectionRepository = collectionRepository
        self.tastingRecordRepository = tastingRecordRepository
        self.recommendPerfumesUseCase = recommendPerfumesUseCase
    }

    func transform(input: Input) -> Output {

        let quickActions = input.viewDidLoad
            .map {
                [
                    HomeQuickAction(type: .perfumeRegister, title: AppStrings.Home.shortcutPerfume, systemImageName: "square.stack.3d.down.right.fill"),
                    HomeQuickAction(type: .tastingNote, title: AppStrings.Home.shortcutTasting, systemImageName: "square.stack.3d.down.right.fill"),
                    HomeQuickAction(type: .report, title: AppStrings.Home.shortcutReport, systemImageName: "square.stack.3d.down.right.fill")
                ]
            }
            .asDriver(onErrorJustReturn: [])

        let sourceData = input.viewDidLoad
            .flatMapLatest { [weak self] _ -> Observable<HomeFeedData?> in
                guard let self else { return .just(nil) }
                return self.fetchHomeFeed()
                    .map(Optional.some)
                    .catchAndReturn(nil)
                    .asObservable()
            }
            .share(replay: 1, scope: .whileConnected)

        let recommendationResult = sourceData
            .flatMapLatest { [weak self] data -> Observable<RecommendationResult?> in
                guard let self, let data else { return .just(nil) }
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
            .map { result -> HomeTasteBannerItem in
                guard let result else { return defaultHomeBanner() }
                return makeHomeBanner(from: result.profile)
            }
            .asDriver(onErrorJustReturn: defaultHomeBanner())

        let profile = Observable.combineLatest(sourceData, recommendationResult)
            .map { source, result -> HomeProfileItem? in
                guard let source, let result else { return nil }
                return HomeProfileItem(
                    profile: result.profile,
                    collectionCount: source.collection.count,
                    tastingCount: source.tastingRecords.count
                )
            }
            .asDriver(onErrorJustReturn: nil)

        let recommendations = recommendationResult
            .withLatestFrom(sourceData) { ($0, $1) }
            .map { payload -> [HomePerfumeItem] in
                let (result, source) = payload
                guard let result, let source else {
                    return []
                }
                let tastingKeys = Set(
                    source.tastingRecords.map {
                        PerfumePresentationSupport.recordKey(
                            perfumeName: $0.perfumeName,
                            brandName: $0.brandName
                        )
                    }
                )
                return result.perfumes.map { recommendation in
                    mapToHomePerfumeItem(
                        recommendation,
                        profile: result.profile,
                        tastingKeys: tastingKeys
                    )
                }
            }
            .do(onNext: { [weak self] items in
                self?.recommendationItemsRelay.accept(items)
            })
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
                return .perfumeDetail(perfume: items[indexPath.item].perfume)
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

    func fetchHomeFeed() -> Single<HomeFeedData> {
        Single.zip(
            userTasteRepository.fetchTasteAnalysis(),
            collectionRepository.fetchCollection().catchAndReturn([]),
            tastingRecordRepository.fetchTastingRecords().catchAndReturn([])
        )
        .map { tasteAnalysis, collection, tastingRecords in
            (
                tasteAnalysis: tasteAnalysis,
                collection: collection,
                tastingRecords: tastingRecords
            )
        }
    }

}

private func mapToHomePerfumeItem(
    _ recommendation: RecommendedPerfume,
    profile: UserTasteProfile,
    tastingKeys: Set<String>
) -> HomePerfumeItem {
    let perfume = recommendation.perfume
    return HomePerfumeItem(
        perfume: perfume,
        id: perfume.id,
        brandName: perfume.brand,
        perfumeName: perfume.name,
        accordsText: makeHomeAccordText(perfume, profile: profile),
        recommendationReason: recommendation.reason,
        imageURL: perfume.imageUrl,
        hasTastingRecord: tastingKeys.contains(
            PerfumePresentationSupport.recordKey(
                perfumeName: perfume.name,
                brandName: perfume.brand
            )
        )
    )
}

private func makeHomeAccordText(_ perfume: Perfume, profile: UserTasteProfile) -> String {
    let accords = prioritizedHomeAccords(perfume, profile: profile)
    return accords.isEmpty
        ? AppStrings.Home.fallbackAccords
        : accords.map { "• \($0)" }.joined(separator: "  ")
}

private func prioritizedHomeAccords(_ perfume: Perfume, profile: UserTasteProfile) -> [String] {
    let canonicalAccords = ScentFamilyNormalizer.canonicalNames(for: perfume.mainAccords)
    guard !canonicalAccords.isEmpty else { return [] }

    let dominantFamilies = canonicalAccords.filter {
        perfume.mainAccordStrengths[$0] == .dominant
    }

    let profileFamilies = Set(profile.preferredFamilies)

    if dominantFamilies.count == 2 {
        return dominantFamilies.sorted { lhs, rhs in
            let lhsMatchesProfile = profileFamilies.contains(lhs)
            let rhsMatchesProfile = profileFamilies.contains(rhs)
            if lhsMatchesProfile != rhsMatchesProfile { return lhsMatchesProfile }

            let lhsStrength = perfume.mainAccordStrengths[lhs]?.weight ?? 0
            let rhsStrength = perfume.mainAccordStrengths[rhs]?.weight ?? 0
            if lhsStrength != rhsStrength { return lhsStrength > rhsStrength }

            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
    }

    if dominantFamilies.count > 2 {
        let sortedDominant = dominantFamilies.sorted { lhs, rhs in
            let lhsMatchesProfile = profileFamilies.contains(lhs)
            let rhsMatchesProfile = profileFamilies.contains(rhs)
            if lhsMatchesProfile != rhsMatchesProfile { return lhsMatchesProfile }

            let lhsStrength = perfume.mainAccordStrengths[lhs]?.weight ?? 0
            let rhsStrength = perfume.mainAccordStrengths[rhs]?.weight ?? 0
            if lhsStrength != rhsStrength { return lhsStrength > rhsStrength }

            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }

        return Array(sortedDominant.prefix(2))
    }

    let sorted = canonicalAccords.sorted { lhs, rhs in
        let lhsDominant = dominantFamilies.contains(lhs)
        let rhsDominant = dominantFamilies.contains(rhs)
        if lhsDominant != rhsDominant { return lhsDominant }

        let lhsMatchesProfile = profileFamilies.contains(lhs)
        let rhsMatchesProfile = profileFamilies.contains(rhs)
        if lhsMatchesProfile != rhsMatchesProfile { return lhsMatchesProfile }

        let lhsStrength = perfume.mainAccordStrengths[lhs]?.weight ?? 0
        let rhsStrength = perfume.mainAccordStrengths[rhs]?.weight ?? 0
        if lhsStrength != rhsStrength { return lhsStrength > rhsStrength }

        return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
    }

    return Array(sorted.prefix(2))
}

private func makeHomeBanner(from profile: UserTasteProfile) -> HomeTasteBannerItem {
    let familyText = profile.displayFamilySummary
    let summary: String
    if !profile.safeStartingPoint.isEmpty {
        summary = profile.safeStartingPoint
    } else if !profile.analysisSummary.isEmpty {
        summary = profile.analysisSummary
    } else if !familyText.isEmpty {
        summary = AppStrings.Home.familySummary(familyText)
    } else {
        summary = AppStrings.Home.emptySummary
    }
    return HomeTasteBannerItem(
        title: profile.displayTitle,
        summary: summary,
        familyText: familyText
    )
}

private func defaultHomeBanner() -> HomeTasteBannerItem {
    HomeTasteBannerItem(
        title: AppStrings.Home.pendingTitle,
        summary: AppStrings.Home.emptySummary,
        familyText: ""
    )
}
