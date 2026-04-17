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

    private let userTasteRepository: UserTasteRepositoryType
    private let collectionRepository: CollectionRepositoryType
    private let tastingRepository: TastingRecordRepositoryType
    private let recommendationEngine: RecommendationEngine

    init(
        userTasteRepository: UserTasteRepositoryType? = nil,
        collectionRepository: CollectionRepositoryType? = nil,
        tastingRepository: TastingRecordRepositoryType? = nil,
        recommendationEngine: RecommendationEngine? = nil
    ) {
        self.userTasteRepository = userTasteRepository ?? UserTasteRepository()
        self.collectionRepository = collectionRepository ?? CollectionRepository()
        self.tastingRepository = tastingRepository ?? TastingRecordRepository()
        self.recommendationEngine = recommendationEngine ?? RecommendationEngine()
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
            .flatMapLatest { [weak self] _ -> Observable<(TasteAnalysisResult, [CollectedPerfume], [TastingRecord])?> in
                guard let self else { return .just(nil) }

                return Single.zip(
                    self.userTasteRepository.fetchTasteAnalysis(),
                    self.collectionRepository.fetchCollection().catchAndReturn([]),
                    self.tastingRepository.fetchTastingRecords().catchAndReturn([])
                )
                .map(Optional.some)
                .catchAndReturn(nil)
                .asObservable()
            }
            .share(replay: 1, scope: .whileConnected)

// MARK: - 추천 결과
    private func loadRecommendation(
        onboarding: OnboardingData,
        collection: [CollectedPerfume],
        tasting: [TastingRecord]
    ) async {
        let result = try? await recommendationEngine.recommend(
            onboarding: onboarding,
            collection: collection,
            tastingRecords: tasting
        )
        await MainActor.run {
            self.recommendationResult = result
            self.banner = result.map { makeBanner(from: $0.profile) } ?? Self.defaultBanner()
            self.profile = result.map {
                HomeProfileItem(
                    profile: $0.profile,
                    collectionCount: collection.count,
                    tastingCount: tasting.count
                )
            }
            self.bannerTitle = result.map { "\($0.profile.primaryProfileName) 취향과 함께" }
                ?? "킁킁 서비스와 함께"
            self.bannerSubtitle = {
                guard let result else { return "나에게 맞는 향수를 찾아가요" }
                let familySummary = result.profile.preferredFamilies.prefix(2).joined(separator: " · ")
                return familySummary.isEmpty ? "나에게 맞는 향수를 찾아가요" : "\(familySummary) 무드의 향수를 찾아가요"
            }()
        }
    }
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

    func makeAccordText(_ perfume: FragellaPerfume) -> String {
        let accords = ScentFamilyNormalizer.canonicalNames(
            for: Array(perfume.mainAccords.prefix(2))
        ).prefix(2)
        return accords.isEmpty
        ? "• Floral  • Musk"
        : accords.map { "• \($0)" }.joined(separator: "  ")
    }

if accords.isEmpty { return "• Floral  • Musky" }
        return accords.map { "• \($0)" }.joined(separator: "  ")
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
