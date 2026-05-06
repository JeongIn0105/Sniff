//
//  OwnedPerfumeRegistrationViewModel.swift
//  Sniff
//

import Foundation
import Combine
import RxSwift

@MainActor
final class OwnedPerfumeRegistrationViewModel: ObservableObject {

    @Published var searchText = ""
    @Published private(set) var searchResults: [Perfume] = []
    @Published private(set) var selectedPerfume: Perfume?
    @Published var usageStatus: CollectedPerfumeUsageStatus?
    @Published var usageFrequency: CollectedPerfumeUsageFrequency?
    @Published var preferenceLevel: CollectedPerfumePreferenceLevel?
    @Published var memo = ""
    @Published private(set) var isSearching = false
    @Published private(set) var isSaving = false
    @Published private(set) var didSave = false
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    private let perfumeCatalogRepository: PerfumeCatalogRepositoryType
    private let collectionRepository: CollectionRepositoryType
    private var ownedPerfumeIDs = Set<String>()
    private var searchTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?
    let maxMemoLength = 100

    var canEditDetails: Bool {
        selectedPerfume != nil
    }

    var canRegister: Bool {
        selectedPerfume != nil
            && usageStatus != nil
            && usageFrequency != nil
            && preferenceLevel != nil
            && !isSaving
    }

    var searchResultCountText: String {
        "검색 결과 \(min(searchResults.count, 3))개"
    }

    var memoCountText: String {
        "\(memo.count) / \(maxMemoLength)"
    }

    init(
        perfumeCatalogRepository: PerfumeCatalogRepositoryType,
        collectionRepository: CollectionRepositoryType
    ) {
        self.perfumeCatalogRepository = perfumeCatalogRepository
        self.collectionRepository = collectionRepository
    }

    deinit {
        searchTask?.cancel()
        toastTask?.cancel()
    }

    func loadOwnedPerfumes() async {
        do {
            let perfumes = try await collectionRepository.fetchCollection().async()
            ownedPerfumeIDs = Set(perfumes.map(\.id))
        } catch {
            // 등록 자체는 검색 후 저장 단계에서 다시 검증되므로 조용히 넘긴다.
        }
    }

    func scheduleSearch() {
        searchTask?.cancel()

        guard selectedPerfume == nil else {
            searchResults = []
            isSearching = false
            return
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await self?.search(query: query)
        }
    }

    func submitSearch() {
        searchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        searchTask = Task { [weak self] in
            await self?.search(query: query)
        }
    }

    func selectPerfume(_ perfume: Perfume) {
        let collectionID = perfume.collectionDocumentID
        guard !ownedPerfumeIDs.contains(collectionID) else {
            showToast(AppStrings.UIKitScreens.Search.registerDuplicate)
            return
        }

        selectedPerfume = perfume
        searchText = PerfumePresentationSupport.displayPerfumeName(perfume.name)
        searchResults = []
        resetRegistrationDetails()
    }

    func clearSelectedPerfume() {
        selectedPerfume = nil
        searchText = ""
        searchResults = []
        resetRegistrationDetails()
    }

    func updateMemo(_ text: String) {
        memo = String(text.prefix(maxMemoLength))
    }

    func register() async {
        guard
            let selectedPerfume,
            let usageStatus,
            let usageFrequency,
            let preferenceLevel,
            canRegister
        else { return }
        let collectionID = selectedPerfume.collectionDocumentID
        guard !ownedPerfumeIDs.contains(collectionID) else {
            showToast(AppStrings.UIKitScreens.Search.registerDuplicate)
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let registrationInfo = CollectedPerfumeRegistrationInfo(
                usageStatus: usageStatus,
                usageFrequency: usageFrequency,
                preferenceLevel: preferenceLevel,
                memo: memo
            )
            try await collectionRepository
                .saveCollectedPerfume(selectedPerfume, registrationInfo: registrationInfo)
                .async()
            ownedPerfumeIDs.insert(collectionID)
            NotificationCenter.default.postPerfumeCollectionDidChange(scope: .owned)
            didSave = true
        } catch let limitError as CollectionUsageLimitError {
            showToast(limitError.localizedDescription)
        } catch {
            errorMessage = AppStrings.UIKitScreens.Search.registerFailed
        }
    }

    func requestDirectInput() {
        showToast("직접 입력은 준비 중이에요")
    }

    private func resetRegistrationDetails() {
        usageStatus = nil
        usageFrequency = nil
        preferenceLevel = nil
        memo = ""
    }

    private func search(query: String) async {
        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await perfumeCatalogRepository.search(query: query, limit: 12).async()
        } catch {
            errorMessage = AppStrings.ViewModelMessages.TastingNoteForm.serverError(
                (error as NSError).code,
                error.localizedDescription
            )
        }
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.toastMessage = nil
            }
        }
    }
}
