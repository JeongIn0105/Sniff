//
//  AppDependencyContainer.swift
//  Sniff
//
//  Created by Codex on 2026.04.20.
//

import Foundation

final class AppDependencyContainer {

    static let shared = AppDependencyContainer()

    init() {}

    lazy var authService: AuthServiceType = AuthService.shared
    lazy var firestoreService: FirestoreService = .shared

    func makePerfumeCatalogRepository() -> PerfumeCatalogRepositoryType {
        PerfumeCatalogRepository()
    }

    func makeCollectionRepository() -> CollectionRepositoryType {
        CollectionRepository(firestoreService: firestoreService)
    }

    func makeTastingRecordRepository() -> TastingRecordRepositoryType {
        TastingRecordRepository(firestoreService: firestoreService)
    }

    func makeUserTasteRepository() -> UserTasteRepositoryType {
        UserTasteRepository(firestoreService: firestoreService)
    }

    func makeUserProfileStatusRepository() -> UserProfileStatusRepositoryType {
        UserProfileStatusRepository()
    }

    func makeRecentSearchStore() -> RecentSearchStoreType {
        RecentSearchStore()
    }

    func makeRecommendPerfumesUseCase() -> RecommendPerfumesUseCaseType {
        let recommendationEngine = RecommendationEngine(
            perfumeCatalogRepository: makePerfumeCatalogRepository()
        )
        return RecommendPerfumesUseCase(recommendationEngine: recommendationEngine)
    }

    @MainActor
    func makeMyPageViewModel() -> MyPageViewModel {
        MyPageViewModel(
            firestoreService: firestoreService,
            collectionRepository: makeCollectionRepository(),
            tastingRepository: makeTastingRecordRepository()
        )
    }

    @MainActor
    func makeTastingNoteViewModel(
        perfumeScope: TastingNotePerfumeScope? = nil
    ) -> TastingNoteViewModel {
        TastingNoteViewModel(
            firestoreService: firestoreService,
            perfumeScope: perfumeScope
        )
    }

    @MainActor
    func makeOwnedPerfumeListViewModel() -> OwnedPerfumeListViewModel {
        OwnedPerfumeListViewModel(
            collectionRepository: makeCollectionRepository(),
            tastingRepository: makeTastingRecordRepository()
        )
    }

    @MainActor
    func makeLikedPerfumeListViewModel() -> LikedPerfumeListViewModel {
        LikedPerfumeListViewModel(
            firestoreService: firestoreService,
            tastingRepository: makeTastingRecordRepository()
        )
    }

    @MainActor
    func makeTastingNoteFormViewModel(
        editingNote: TastingNote? = nil,
        initialPerfume: Perfume? = nil
    ) -> TastingNoteFormViewModel {
        TastingNoteFormViewModel(
            editingNote: editingNote,
            initialPerfume: initialPerfume
        )
    }

    @MainActor
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            firestoreService: firestoreService,
            authService: authService
        )
    }

    @MainActor
    func makeAccountInfoViewModel() -> AccountInfoViewModel {
        AccountInfoViewModel(firestoreService: firestoreService)
    }

    @MainActor
    func makeEmailChangeViewModel() -> EmailChangeViewModel {
        EmailChangeViewModel(firestoreService: firestoreService)
    }

    @MainActor
    func makeDeviceManageViewModel() -> DeviceManageViewModel {
        DeviceManageViewModel()
    }
}
