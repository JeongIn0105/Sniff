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
        let bannerTitle: Driver<String>
        let bannerSubtitle: Driver<String>
        let quickActions: Driver<[HomeQuickAction]>
        let recommendations: Driver<[HomePerfumeItem]>
        let route: Signal<HomeRoute>
    }

    private let disposeBag = DisposeBag()
    private let routeRelay = PublishRelay<HomeRoute>()
    private let recommendationItemsRelay = BehaviorRelay<[HomePerfumeItem]>(value: [])

    private let userTasteRepository: UserTasteRepositoryType
    private let collectionRepository: CollectionRepositoryType
    private let tastingRepository: TastingRecordRepositoryType
    private let recommendationEngine: RecommendationEngine

    init(
        userTasteRepository: UserTasteRepositoryType = UserTasteRepository(),
        collectionRepository: CollectionRepositoryType = CollectionRepository(),
        tastingRepository: TastingRecordRepositoryType = TastingRecordRepository(),
        recommendationEngine: RecommendationEngine = RecommendationEngine()
    ) {
        self.userTasteRepository = userTasteRepository
        self.collectionRepository = collectionRepository
        self.tastingRepository = tastingRepository
        self.recommendationEngine = recommendationEngine
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

        let recommendationResult = input.viewDidLoad
            .flatMapLatest { [weak self] _ -> Observable<RecommendationResult?> in
                guard let self else { return .just(nil) }

                return Single.zip(
                    self.userTasteRepository.fetchTasteAnalysis(),
                    self.collectionRepository.fetchCollection(),
                    self.tastingRepository.fetchTastingRecords()
                )
                .flatMap { onboarding, collection, tasting in
                    self.recommendationEngine.recommend(
                        onboarding: onboarding,
                        collection: collection,
                        tastingRecords: tasting
                    )
                }
                .map(Optional.some)
                .catchAndReturn(nil)
                .asObservable()
            }
            .share(replay: 1, scope: .whileConnected)

        let bannerTitle = recommendationResult
            .map { result in
                guard let result else { return "킁킁 서비스와 함께" }
                return "\(result.profile.primaryProfileName) 취향과 함께"
            }
            .asDriver(onErrorJustReturn: "킁킁 서비스와 함께")

        let bannerSubtitle = recommendationResult
            .map { result in
                guard let result else { return "나에게 맞는 향수를 찾아가요" }

                let familySummary = result.profile.preferredFamilies
                    .prefix(2)
                    .joined(separator: " · ")

                if familySummary.isEmpty {
                    return "나에게 맞는 향수를 찾아가요"
                }

                return "\(familySummary) 무드의 향수를 찾아가요"
            }
            .asDriver(onErrorJustReturn: "나에게 맞는 향수를 찾아가요")

        let recommendations = recommendationResult
            .map { [weak self] result -> [HomePerfumeItem] in
                guard let self, let result else { return [] }
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
            .withLatestFrom(recommendationItemsRelay.asObservable()) { indexPath, items in
                (indexPath, items)
            }
            .compactMap { indexPath, items -> HomeRoute? in
                guard items.indices.contains(indexPath.item) else { return nil }
                return .perfumeDetail(id: items[indexPath.item].id)
            }
            .bind(to: routeRelay)
            .disposed(by: disposeBag)

        return Output(
            bannerTitle: bannerTitle,
            bannerSubtitle: bannerSubtitle,
            quickActions: quickActions,
            recommendations: recommendations,
            route: routeRelay.asSignal()
        )
    }
}

private extension HomeViewModel {

    func mapToHomePerfumeItem(_ perfume: FragellaPerfume) -> HomePerfumeItem {
        HomePerfumeItem(
            id: Int(perfume.id) ?? 0,
            brandName: perfume.brand,
            perfumeName: perfume.name,
            accordsText: makeAccordText(perfume),
            recommendationReason: "",
            imageURL: perfume.imageUrl
        )
    }

    func makeAccordText(_ perfume: FragellaPerfume) -> String {
        let accords = [perfume.scentFamily, perfume.scentFamily2]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .prefix(2)

        if accords.isEmpty {
            return "• Floral  • Musky"
        }

        return accords
            .map { "• \($0)" }
            .joined(separator: "  ")
    }
}
