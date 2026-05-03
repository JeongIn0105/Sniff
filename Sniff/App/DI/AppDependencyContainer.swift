//
//  AppDependencyContainer.swift
//  Sniff
//
//  Created by Codex on 2026.04.20.
//

import Foundation
import FirebaseAuth

final class AppDependencyContainer {

    static let shared = AppDependencyContainer()

    init() {}

    lazy var authService: AuthServiceType = AuthService.shared
    lazy var firestoreService: FirestoreService = .shared
    lazy var coreDataStack: CoreDataStack = .shared
    lazy var userTasteRepository: UserTasteRepositoryType = UserTasteRepository(
        firestoreService: firestoreService
    )
    @MainActor lazy var localTastingNoteRepository = LocalTastingNoteRepository(
        coreDataStack: coreDataStack,
        userTasteRepository: userTasteRepository
    )

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
        userTasteRepository
    }

    func makeUserProfileStatusRepository() -> UserProfileStatusRepositoryType {
        UserProfileStatusRepository()
    }

    func makeRecentSearchStore() -> RecentSearchStoreType {
        // 현재 로그인된 유저 UID를 키에 포함하여 계정별 검색어 분리
        let userID = Auth.auth().currentUser?.uid
        return RecentSearchStore(userID: userID)
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
            tastingRepository: makeTastingRecordRepository(),
            localTastingNoteRepository: localTastingNoteRepository,
            userTasteRepository: userTasteRepository
        )
    }

    @MainActor
    func makeTastingNoteViewModel(
        perfumeScope: TastingNotePerfumeScope? = nil
    ) -> TastingNoteViewModel {
        TastingNoteViewModel(
            firestoreService: firestoreService,
            localRepository: localTastingNoteRepository,
            perfumeScope: perfumeScope
        )
    }

    @MainActor
    func makeOwnedPerfumeListViewModel() -> OwnedPerfumeListViewModel {
        OwnedPerfumeListViewModel(
            collectionRepository: makeCollectionRepository(),
            tastingRepository: makeTastingRecordRepository(),
            localTastingNoteRepository: localTastingNoteRepository
        )
    }

    @MainActor
    func makeLikedPerfumeListViewModel() -> LikedPerfumeListViewModel {
        LikedPerfumeListViewModel(
            firestoreService: firestoreService,
            tastingRepository: makeTastingRecordRepository(),
            localTastingNoteRepository: localTastingNoteRepository
        )
    }

    @MainActor
    func makeTastingNoteFormViewModel(
        editingNote: TastingNote? = nil,
        initialPerfume: Perfume? = nil
    ) -> TastingNoteFormViewModel {
        TastingNoteFormViewModel(
            localRepository: localTastingNoteRepository,
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
}
