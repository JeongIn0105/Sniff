//
//  MyPageViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import Combine
import FirebaseAuth
import RxSwift

@MainActor
final class MyPageViewModel: ObservableObject {

    struct ProfileInfo {
        let nickname: String
        let email: String?
    }

    struct OwnedPreviewItem: Identifiable {
        let id: String
        let name: String
        let brand: String
        let imageURL: String?
        let accordTags: [String]
        let hasTastingRecord: Bool
        let isLiked: Bool
        let sourcePerfume: Perfume
    }

    struct LikedPreviewItem: Identifiable {
        let id: String
        let name: String
        let brand: String
        let imageURL: String?
        let accordTags: [String]
        let hasTastingRecord: Bool
        let sourcePerfume: Perfume
    }

    @Published private(set) var profileInfo: ProfileInfo?
    @Published private(set) var ownedPerfumes: [OwnedPreviewItem] = []
    @Published private(set) var likedPerfumes: [LikedPreviewItem] = []
    @Published private(set) var tasteProfileItem: HomeViewModel.HomeProfileItem?
    @Published private(set) var ownedCount: Int = 0
    @Published private(set) var likedCount: Int = 0
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var toastMessage: String?

    private enum DisplayLimit {
        static let ownedPreview = 5
        static let likedPreview = 10
    }

    /// Preview 전용 플래그 — true이면 load()를 실행하지 않음
    var isMock = false

    private let firestoreService: FirestoreService
    private let collectionRepository: CollectionRepositoryType
    private let tastingRepository: TastingRecordRepositoryType
    private let localTastingNoteRepository: LocalTastingNoteRepository
    private let userTasteRepository: UserTasteRepositoryType
    private let preferenceAggregator = PreferenceAggregator()
    private var allOwnedPerfumes: [OwnedPreviewItem] = []
    private var allLikedPerfumes: [LikedPreviewItem] = []
    private var toastTask: Task<Void, Never>?

    init(
        firestoreService: FirestoreService,
        collectionRepository: CollectionRepositoryType,
        tastingRepository: TastingRecordRepositoryType,
        localTastingNoteRepository: LocalTastingNoteRepository,
        userTasteRepository: UserTasteRepositoryType
    ) {
        self.firestoreService = firestoreService
        self.collectionRepository = collectionRepository
        self.tastingRepository = tastingRepository
        self.localTastingNoteRepository = localTastingNoteRepository
        self.userTasteRepository = userTasteRepository
    }

    deinit {
        toastTask?.cancel()
    }

    func load() async {
        // Preview 목 데이터 사용 시 Firebase 호출 생략
        guard !isMock else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            profileInfo = try await fetchProfileInfo()

            async let collectionFetch = fetchCollectionResult()
            async let likedFetch = fetchLikedPerfumesResult()
            async let tastingKeyFetch = fetchTastingKeys()
            async let tastingImageURLFetch = fetchTastingImageURLs()
            async let tasteAnalysisFetch = fetchTasteAnalysisResult()
            async let tastingRecordsFetch = fetchTastingRecordsResult()

            let collectionResult = await collectionFetch
            let likedResult = await likedFetch
            let tastingKeys = await tastingKeyFetch
            let tastingImageURLs = await tastingImageURLFetch
            let tasteAnalysisResult = await tasteAnalysisFetch
            let tastingRecordsResult = await tastingRecordsFetch

            updateTasteProfile(
                tasteAnalysisResult: tasteAnalysisResult,
                collectionResult: collectionResult,
                tastingRecordsResult: tastingRecordsResult
            )

            switch collectionResult {
            case .success(let collection):
                let likedIDs = likedResult.likedIDs
                allOwnedPerfumes = collection.map {
                    makeOwnedPreviewItem(from: $0, tastingKeys: tastingKeys, likedIDs: likedIDs)
                }
                ownedCount = allOwnedPerfumes.count
                ownedPerfumes = Array(allOwnedPerfumes.prefix(DisplayLimit.ownedPreview))
            case .failure:
                ownedCount = 0
                allOwnedPerfumes = []
                ownedPerfumes = []
            }

            switch likedResult {
            case .success(let liked):
                let collection = collectionResult.collectionItems
                var fallbackImageURLs = collectionResult.collectionImageURLs
                tastingImageURLs.forEach { key, value in
                    fallbackImageURLs[key] = fallbackImageURLs[key] ?? value
                }

                // collection에서 직접 이미지 URL 매핑 (raw string)
                // makeOwnedPreviewItem이 perfume.imageUrl을 직접 쓰는 것과 동일한 방식
                let collectionImageByID: [String: String] = collection.reduce(into: [:]) { map, item in
                    guard let url = item.imageUrl else { return }
                    map[item.id] = url
                }
                let collectionImageByRecordKey: [String: String] = collection.reduce(into: [:]) { map, item in
                    guard let url = item.imageUrl else { return }
                    PerfumePresentationSupport.recordMatchingKeys(
                        perfumeName: item.name,
                        brandName: item.brand
                    ).forEach { key in if map[key] == nil { map[key] = url } }
                }

                allLikedPerfumes = liked.map { likedPerfume in
                    // 이미지 URL 우선순위: likes doc → collection ID 매칭 → 이름+브랜드 매칭
                    let resolvedImageURL: String? = likedPerfume.imageURL
                        ?? collectionImageByID[likedPerfume.id]
                        ?? PerfumePresentationSupport.recordMatchingKeys(
                            perfumeName: likedPerfume.name,
                            brandName: likedPerfume.brand
                        ).compactMap { collectionImageByRecordKey[$0] }.first

                    // sourcePerfume은 상세 화면 진입 등 내비게이션에 사용
                    let sourcePerfume = likedPerfume.toPerfume()

                    // hasTastingRecord 계산
                    let hasTasting = tastingKeys.contains(
                        PerfumePresentationSupport.recordKey(
                            perfumeName: likedPerfume.name,
                            brandName: likedPerfume.brand
                        )
                    ) || !tastingKeys.isDisjoint(with: PerfumePresentationSupport.recordMatchingKeys(
                        perfumeName: likedPerfume.name,
                        brandName: likedPerfume.brand
                    ))

                    // imageURL을 resolvedImageURL로 직접 주입 (resolvedImageURL() 함수 우회)
                    return LikedPreviewItem(
                        id: likedPerfume.id,
                        name: likedPerfume.name,
                        brand: likedPerfume.brand,
                        imageURL: resolvedImageURL,
                        accordTags: PerfumePresentationSupport.previewAccords(
                            mainAccords: likedPerfume.mainAccords,
                            fallback: likedPerfume.scentFamilies
                        ),
                        hasTastingRecord: hasTasting,
                        sourcePerfume: sourcePerfume
                    )
                }
                likedCount = allLikedPerfumes.count
                likedPerfumes = Array(allLikedPerfumes.prefix(DisplayLimit.likedPreview))
            case .failure:
                likedCount = 0
                allLikedPerfumes = []
                likedPerfumes = []
            }
        } catch {
            errorMessage = error.localizedDescription
            if profileInfo == nil {
                profileInfo = fallbackProfileInfo()
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func toggleOwnedPerfumeLike(id: String) async {
        guard let ownedIndex = allOwnedPerfumes.firstIndex(where: { $0.id == id }) else { return }

        let ownedItem = allOwnedPerfumes[ownedIndex]
        let willLike = !ownedItem.isLiked
        let previousOwned = allOwnedPerfumes
        let previousLiked = allLikedPerfumes
        let previousLikedCount = likedCount

        allOwnedPerfumes[ownedIndex] = OwnedPreviewItem(
            id: ownedItem.id,
            name: ownedItem.name,
            brand: ownedItem.brand,
            imageURL: ownedItem.imageURL,
            accordTags: ownedItem.accordTags,
            hasTastingRecord: ownedItem.hasTastingRecord,
            isLiked: willLike,
            sourcePerfume: ownedItem.sourcePerfume
        )

        if willLike {
            if !allLikedPerfumes.contains(where: { $0.id == ownedItem.id }) {
                let hasTastingRecord = ownedItem.hasTastingRecord
                allLikedPerfumes.insert(
                    LikedPreviewItem(
                        id: ownedItem.id,
                        name: ownedItem.name,
                        brand: ownedItem.brand,
                        imageURL: ownedItem.imageURL,
                        accordTags: ownedItem.accordTags,
                        hasTastingRecord: hasTastingRecord,
                        sourcePerfume: ownedItem.sourcePerfume
                    ),
                    at: 0
                )
            }
            likedCount += 1
        } else {
            allLikedPerfumes.removeAll { $0.id == ownedItem.id }
            likedCount = max(0, likedCount - 1)
        }
        applyPreviewLimits()

        do {
            if willLike {
                try await collectionRepository.saveLikedPerfume(ownedItem.sourcePerfume).async()
            } else {
                try await collectionRepository.deleteLikedPerfume(id: ownedItem.id).async()
            }
        } catch {
            allOwnedPerfumes = previousOwned
            allLikedPerfumes = previousLiked
            likedCount = previousLikedCount
            applyPreviewLimits()
            handleError(error)
        }
    }

    func removeLikedPerfume(id: String) async {
        let previousLiked = allLikedPerfumes
        let previousLikedCount = likedCount
        let previousOwned = allOwnedPerfumes

        allLikedPerfumes.removeAll { $0.id == id }
        likedCount = max(0, likedCount - 1)

        if let ownedIndex = allOwnedPerfumes.firstIndex(where: { $0.id == id }) {
            let item = allOwnedPerfumes[ownedIndex]
            allOwnedPerfumes[ownedIndex] = OwnedPreviewItem(
                id: item.id,
                name: item.name,
                brand: item.brand,
                imageURL: item.imageURL,
                accordTags: item.accordTags,
                hasTastingRecord: item.hasTastingRecord,
                isLiked: false,
                sourcePerfume: item.sourcePerfume
            )
        }
        applyPreviewLimits()

        do {
            try await collectionRepository.deleteLikedPerfume(id: id).async()
        } catch {
            allLikedPerfumes = previousLiked
            likedCount = previousLikedCount
            allOwnedPerfumes = previousOwned
            applyPreviewLimits()
            handleError(error)
        }
    }
}

private extension MyPageViewModel {

    func fetchProfileInfo() async throws -> ProfileInfo {
        do {
            let user = try await firestoreService.fetchUserProfile()
            return ProfileInfo(nickname: user.nickname, email: user.email)
        } catch FirestoreServiceError.invalidUserProfile {
            return fallbackProfileInfo()
        }
    }

    func fallbackProfileInfo() -> ProfileInfo {
        let email = Auth.auth().currentUser?.email
        let nickname = email?.split(separator: "@").first.map(String.init).flatMap {
            $0.isEmpty ? nil : $0
        } ?? "사용자"

        return ProfileInfo(nickname: nickname, email: email)
    }

    func fetchCollectionItems() async throws -> [CollectedPerfume] {
        try await collectionRepository.fetchCollection().async()
    }

    func fetchCollectionResult() async -> Result<[CollectedPerfume], Error> {
        do {
            return .success(try await fetchCollectionItems())
        } catch {
            return .failure(error)
        }
    }

    func fetchLikedPerfumesResult() async -> Result<[LikedPerfume], Error> {
        do {
            return .success(try await collectionRepository.fetchLikedPerfumes().async())
        } catch {
            return .failure(error)
        }
    }

    func fetchTasteAnalysisResult() async -> Result<TasteAnalysisResult, Error> {
        do {
            return .success(try await userTasteRepository.fetchTasteAnalysis().async())
        } catch {
            return .failure(error)
        }
    }

    func fetchTastingRecordsResult() async -> Result<[TastingRecord], Error> {
        do {
            return .success(try await tastingRepository.fetchTastingRecords().async())
        } catch {
            return .failure(error)
        }
    }

    func updateTasteProfile(
        tasteAnalysisResult: Result<TasteAnalysisResult, Error>,
        collectionResult: Result<[CollectedPerfume], Error>,
        tastingRecordsResult: Result<[TastingRecord], Error>
    ) {
        guard case .success(let tasteAnalysis) = tasteAnalysisResult else {
            tasteProfileItem = nil
            return
        }

        let collection = collectionResult.collectionItems
        let tastingRecords = tastingRecordsResult.tastingRecords
        let profile = preferenceAggregator.aggregate(
            onboarding: tasteAnalysis,
            collection: collection,
            tastingRecords: tastingRecords
        )

        tasteProfileItem = HomeViewModel.HomeProfileItem(
            profile: profile,
            collectionCount: collection.count,
            tastingCount: tastingRecords.count
        )
    }

    func makeOwnedPreviewItem(from perfume: CollectedPerfume) -> OwnedPreviewItem {
        makeOwnedPreviewItem(from: perfume, tastingKeys: [], likedIDs: [])
    }

    func makeOwnedPreviewItem(
        from perfume: CollectedPerfume,
        tastingKeys: Set<String>,
        likedIDs: Set<String>
    ) -> OwnedPreviewItem {
        let sourcePerfume = perfume.toPerfume()

        return OwnedPreviewItem(
            id: perfume.id,
            name: perfume.name,
            brand: perfume.brand,
            imageURL: perfume.imageUrl,
            accordTags: PerfumePresentationSupport.previewAccords(
                mainAccords: perfume.mainAccords,
                fallback: perfume.scentFamilies
            ),
            hasTastingRecord: tastingKeys.contains(
                PerfumePresentationSupport.recordKey(
                    perfumeName: perfume.name,
                    brandName: perfume.brand
                )
            ) || !tastingKeys.isDisjoint(with: PerfumePresentationSupport.recordMatchingKeys(
                perfumeName: perfume.name,
                brandName: perfume.brand
            )),
            isLiked: likedIDs.contains(perfume.id),
            sourcePerfume: sourcePerfume
        )
    }

    func makeLikedPreviewItem(from perfume: LikedPerfume) -> LikedPreviewItem {
        makeLikedPreviewItem(from: perfume.toPerfume(), tastingKeys: [])
    }

    func makeLikedPreviewItem(
        from perfume: Perfume,
        tastingKeys: Set<String>,
        collection: [CollectedPerfume] = [],
        fallbackImageURLs: [String: String] = [:]
    ) -> LikedPreviewItem {
        let imageURL = resolvedImageURL(
            for: perfume,
            collection: collection,
            fallbackImageURLs: fallbackImageURLs
        )
        let sourcePerfume = Perfume(
            id: perfume.id,
            name: perfume.name,
            brand: perfume.brand,
            nameAliases: perfume.nameAliases,
            brandAliases: perfume.brandAliases,
            imageUrl: imageURL,
            rawMainAccords: perfume.rawMainAccords,
            mainAccords: perfume.mainAccords,
            mainAccordStrengths: perfume.mainAccordStrengths,
            topNotes: perfume.topNotes,
            middleNotes: perfume.middleNotes,
            baseNotes: perfume.baseNotes,
            concentration: perfume.concentration,
            gender: perfume.gender,
            season: perfume.season,
            seasonRanking: perfume.seasonRanking,
            situation: perfume.situation,
            longevity: perfume.longevity,
            sillage: perfume.sillage
        )

        return LikedPreviewItem(
            id: perfume.id,
            name: perfume.name,
            brand: perfume.brand,
            imageURL: imageURL,
            accordTags: PerfumePresentationSupport.previewAccords(
                mainAccords: perfume.mainAccords,
                fallback: perfume.mainAccords
            ),
            hasTastingRecord: tastingKeys.contains(
                PerfumePresentationSupport.recordKey(
                    perfumeName: perfume.name,
                    brandName: perfume.brand
                )
            ) || !tastingKeys.isDisjoint(with: PerfumePresentationSupport.recordMatchingKeys(
                perfumeName: perfume.name,
                brandName: perfume.brand
            )),
            sourcePerfume: sourcePerfume
        )
    }

    func resolvedImageURL(
        for perfume: Perfume,
        collection: [CollectedPerfume],
        fallbackImageURLs: [String: String]
    ) -> String? {
        if let imageURL = normalizedImageURL(perfume.imageUrl) {
            return imageURL
        }

        if let matchedByID = collection.first(where: { $0.id == perfume.id }),
           let imageURL = normalizedImageURL(matchedByID.imageUrl) {
            return imageURL
        }

        let perfumeKeys = PerfumePresentationSupport.recordMatchingKeys(
            perfumeName: perfume.name,
            brandName: perfume.brand
        )

        if let matchedByRecordKey = collection.first(where: { item in
            !perfumeKeys.isDisjoint(with: PerfumePresentationSupport.recordMatchingKeys(
                perfumeName: item.name,
                brandName: item.brand
            ))
        }),
           let imageURL = normalizedImageURL(matchedByRecordKey.imageUrl) {
            return imageURL
        }

        let displayBrand = normalizedDisplayValue(PerfumePresentationSupport.displayBrand(perfume.brand))
        let displayName = normalizedDisplayValue(PerfumePresentationSupport.displayPerfumeName(perfume.name))

        if let matchedByDisplay = collection.first(where: { item in
            normalizedDisplayValue(PerfumePresentationSupport.displayBrand(item.brand)) == displayBrand
            && normalizedDisplayValue(PerfumePresentationSupport.displayPerfumeName(item.name)) == displayName
        }),
           let imageURL = normalizedImageURL(matchedByDisplay.imageUrl) {
            return imageURL
        }

        let nameOnlyMatches = collection.filter {
            normalizedDisplayValue(PerfumePresentationSupport.displayPerfumeName($0.name)) == displayName
        }
        if nameOnlyMatches.count == 1,
           let imageURL = normalizedImageURL(nameOnlyMatches[0].imageUrl) {
            return imageURL
        }

        return perfumeKeys.compactMap { normalizedImageURL(fallbackImageURLs[$0]) }.first
    }

    func normalizedImageURL(_ imageURL: String?) -> String? {
        guard let imageURL = imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !imageURL.isEmpty
        else { return nil }
        return imageURL
    }

    func normalizedDisplayValue(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "ko_KR"))
            .lowercased()
    }

    func fetchTastingKeys() async -> Set<String> {
        var keys = Set<String>()

        do {
            let localNotes = try localTastingNoteRepository.loadNotes()
            keys.formUnion(localNotes.flatMap {
                PerfumePresentationSupport.recordMatchingKeys(
                    perfumeName: $0.perfumeName,
                    brandName: $0.brandName
                )
            })
        } catch {
            // 로컬 시향 기록 로딩 실패 시 원격 기록으로 보완한다.
        }

        do {
            let records = try await tastingRepository.fetchTastingRecords().async()

            keys.formUnion(
                records.flatMap { record in
                    PerfumePresentationSupport.recordMatchingKeys(
                        perfumeName: record.perfumeName,
                        brandName: record.brandName
                    )
                }
            )
        } catch {
            return keys
        }

        return keys
    }

    func fetchTastingImageURLs() async -> [String: String] {
        do {
            let localNotes = try localTastingNoteRepository.loadNotes()
            return localNotes.reduce(into: [String: String]()) { result, note in
                guard let imageURL = note.perfumeImageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !imageURL.isEmpty
                else { return }

                PerfumePresentationSupport.recordMatchingKeys(
                    perfumeName: note.perfumeName,
                    brandName: note.brandName
                ).forEach { key in
                    result[key] = result[key] ?? imageURL
                }
            }
        } catch {
            return [:]
        }
    }

    func applyPreviewLimits() {
        ownedPerfumes = Array(allOwnedPerfumes.prefix(DisplayLimit.ownedPreview))
        likedPerfumes = Array(allLikedPerfumes.prefix(DisplayLimit.likedPreview))
    }

    func handleError(_ error: Error) {
        if let limitError = error as? CollectionUsageLimitError {
            showToast(message: limitError.localizedDescription)
        } else {
            errorMessage = error.localizedDescription
        }
    }

    func showToast(message: String) {
        toastMessage = message
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            toastMessage = nil
        }
    }
}

private extension Result where Success == [CollectedPerfume], Failure == Error {
    var collectionItems: [CollectedPerfume] {
        guard case .success(let collection) = self else { return [] }
        return collection
    }

    var collectionImageURLs: [String: String] {
        guard case .success(let collection) = self else { return [:] }

        return collection.reduce(into: [String: String]()) { result, perfume in
            guard let imageURL = perfume.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !imageURL.isEmpty
            else { return }

            PerfumePresentationSupport.recordMatchingKeys(
                perfumeName: perfume.name,
                brandName: perfume.brand
            ).forEach { key in
                result[key] = result[key] ?? imageURL
            }
        }
    }
}

private extension Result where Success == [LikedPerfume], Failure == Error {
    var likedIDs: Set<String> {
        guard case .success(let likedPerfumes) = self else { return [] }
        return Set(likedPerfumes.map(\.id))
    }
}

private extension Result where Success == [TastingRecord], Failure == Error {
    var tastingRecords: [TastingRecord] {
        guard case .success(let records) = self else { return [] }
        return records
    }
}

// MARK: - Preview 전용 목 데이터

#if DEBUG
extension MyPageViewModel {

    /// SwiftUI Preview 전용 목 뷰모델
    @MainActor
    static func mock() -> MyPageViewModel {
        let dependencyContainer = AppDependencyContainer.shared
        let vm = MyPageViewModel(
            firestoreService: dependencyContainer.firestoreService,
            collectionRepository: dependencyContainer.makeCollectionRepository(),
            tastingRepository: dependencyContainer.makeTastingRecordRepository(),
            localTastingNoteRepository: dependencyContainer.localTastingNoteRepository,
            userTasteRepository: dependencyContainer.userTasteRepository
        )
        vm.isMock = true
        vm.profileInfo = ProfileInfo(nickname: "강지수", email: "asdgh1423@gmail.com")
        vm.tasteProfileItem = HomeViewModel.HomeProfileItem(
            profile: UserTasteProfile(
                tasteTitle: "깨끗하고 자연스러운 취향",
                analysisSummary: "시트러스나 워터리 계열처럼 가볍고 산뜻한 향으로 부담 없이 시작해보시는 걸 추천해요.",
                preferredImpressions: ["깨끗한", "자연스러운"],
                preferredFamilies: ["Citrus", "Water"],
                intensityLevel: "light",
                safeStartingPoint: "Citrus",
                familyScores: ["Citrus": 0.6, "Water": 0.4],
                scentVector: ["Citrus": 0.6, "Water": 0.4],
                stage: .onboardingCollection
            ),
            collectionCount: 3,
            tastingCount: 2
        )
        vm.ownedCount = 3
        vm.ownedPerfumes = [
            OwnedPreviewItem(
                id: "1", name: "어나더 13 오 드 퍼퓸", brand: "르 라보",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.25186.jpg",
                accordTags: ["Floral", "Musky"],
                hasTastingRecord: true, isLiked: false,
                sourcePerfume: Perfume(
                    id: "1", name: "Another 13 Eau de Parfum", brand: "Le Labo",
                    imageUrl: "https://fimgs.net/mdimg/perfume/375x500.25186.jpg",
                    rawMainAccords: ["Floral", "Musky"], mainAccords: ["Floral", "Musky"],
                    topNotes: nil, middleNotes: nil, baseNotes: nil,
                    concentration: nil, gender: nil, season: nil, situation: nil,
                    longevity: nil, sillage: nil
                )
            ),
            OwnedPreviewItem(
                id: "2", name: "블랑쉬 오 드 퍼퓸", brand: "바이레도",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.17770.jpg",
                accordTags: ["Musky", "Powdery"],
                hasTastingRecord: false, isLiked: true,
                sourcePerfume: Perfume(
                    id: "2", name: "Blanche Eau de Parfum", brand: "Byredo",
                    imageUrl: "https://fimgs.net/mdimg/perfume/375x500.17770.jpg",
                    rawMainAccords: ["Musky", "Powdery"], mainAccords: ["Musky", "Powdery"],
                    topNotes: nil, middleNotes: nil, baseNotes: nil,
                    concentration: nil, gender: nil, season: nil, situation: nil,
                    longevity: nil, sillage: nil
                )
            ),
            OwnedPreviewItem(
                id: "3", name: "포 허 오드 퍼퓸", brand: "나르시소 로드리게스",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.4880.jpg",
                accordTags: ["Musky", "Woody"],
                hasTastingRecord: true, isLiked: false,
                sourcePerfume: Perfume(
                    id: "3", name: "For Her Eau de Parfum", brand: "Narciso Rodriguez",
                    imageUrl: "https://fimgs.net/mdimg/perfume/375x500.4880.jpg",
                    rawMainAccords: ["Musky", "Woody"], mainAccords: ["Musky", "Woody"],
                    topNotes: nil, middleNotes: nil, baseNotes: nil,
                    concentration: nil, gender: nil, season: nil, situation: nil,
                    longevity: nil, sillage: nil
                )
            )
        ]
        vm.likedCount = 3
        vm.likedPerfumes = [
            LikedPreviewItem(
                id: "1", name: "어나더 13 오 드 퍼퓸", brand: "르 라보",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.25186.jpg",
                accordTags: ["Floral", "Musky"],
                hasTastingRecord: true,
                sourcePerfume: Perfume(
                    id: "1", name: "Another 13 Eau de Parfum", brand: "Le Labo",
                    imageUrl: "https://fimgs.net/mdimg/perfume/375x500.25186.jpg",
                    rawMainAccords: ["Floral", "Musky"], mainAccords: ["Floral", "Musky"],
                    topNotes: nil, middleNotes: nil, baseNotes: nil,
                    concentration: nil, gender: nil, season: nil, situation: nil,
                    longevity: nil, sillage: nil
                )
            ),
            LikedPreviewItem(
                id: "2", name: "블랑쉬 오 드 퍼퓸", brand: "바이레도",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.17770.jpg",
                accordTags: ["Musky", "Powdery"],
                hasTastingRecord: false,
                sourcePerfume: Perfume(
                    id: "2", name: "Blanche Eau de Parfum", brand: "Byredo",
                    imageUrl: "https://fimgs.net/mdimg/perfume/375x500.17770.jpg",
                    rawMainAccords: ["Musky", "Powdery"], mainAccords: ["Musky", "Powdery"],
                    topNotes: nil, middleNotes: nil, baseNotes: nil,
                    concentration: nil, gender: nil, season: nil, situation: nil,
                    longevity: nil, sillage: nil
                )
            ),
            LikedPreviewItem(
                id: "3", name: "포 허 오드 퍼퓸", brand: "나르시소 로드리게스",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.4880.jpg",
                accordTags: ["Musky", "Woody"],
                hasTastingRecord: true,
                sourcePerfume: Perfume(
                    id: "3", name: "For Her Eau de Parfum", brand: "Narciso Rodriguez",
                    imageUrl: "https://fimgs.net/mdimg/perfume/375x500.4880.jpg",
                    rawMainAccords: ["Musky", "Woody"], mainAccords: ["Musky", "Woody"],
                    topNotes: nil, middleNotes: nil, baseNotes: nil,
                    concentration: nil, gender: nil, season: nil, situation: nil,
                    longevity: nil, sillage: nil
                )
            )
        ]
        return vm
    }
}
#endif
