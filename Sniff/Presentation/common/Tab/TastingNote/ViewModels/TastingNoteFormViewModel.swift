//
//  TastingNoteFormViewModel.swift
//  Sniff
//
//  Created by 이정인 on 4/16/26.
//

// MARK: - 등록 로직
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class TastingNoteFormViewModel: ObservableObject {

    // MARK: - Published (향수 정보)

    @Published var perfumeName: String = ""
    @Published var brandName: String = ""
    @Published var mainAccords: [String] = []
    @Published var concentration: String = ""

    // MARK: - Published (직접 입력)

    @Published var rating: Int = 0
    @Published var selectedMoodTags: Set<String> = []
    @Published var revisitDesire: String? = nil   // 다시 쓰고 싶은지 (단일 선택, 선택 안 해도 저장 가능)
    @Published var memo: String = ""

    // MARK: - Published (상태)

    @Published private(set) var isSaving: Bool = false
    @Published private(set) var saveSuccess: Bool = false
    @Published private(set) var savedPerfumeName: String = ""
    @Published var errorMessage: String?

    // MARK: - Public

    var allMoodTags: [String] { kMoodTagList }

    private var editingNote: TastingNote?
    private let localRepository: LocalTastingNoteRepository
    var isEditMode: Bool { editingNote != nil }
    var navigationTitle: String { isEditMode ? AppStrings.TastingNoteUI.List.edit : AppStrings.TastingNoteUI.List.add }

    var canSave: Bool {
        !perfumeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isMemoValid
    }

    var memoCount: Int { memo.count }
    var maxMemoCount: Int { Self.maxMemoCount }

    var isMemoValid: Bool {
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedMemo.count >= Self.minMemoCount,
              trimmedMemo.count <= Self.maxMemoCount else {
            return false
        }

        var containsLetter = false

        for scalar in trimmedMemo.unicodeScalars {
            if Self.isKoreanScalar(scalar) || Self.isEnglishScalar(scalar) {
                containsLetter = true
                continue
            }

            if Self.isNumberScalar(scalar) ||
                Self.allowedWhitespaceScalars.contains(scalar) ||
                Self.allowedPunctuationScalars.contains(scalar) {
                continue
            }

            return false
        }

        return containsLetter
    }

    // MARK: - Private

    private static let minMemoCount = 20
    private static let maxMemoCount = 2000
    private static let allowedWhitespaceScalars = CharacterSet.whitespacesAndNewlines
    private static let allowedPunctuationScalars = CharacterSet(charactersIn: ".,!?~")

    private var perfumeImageURL: String?

    private var uid: String? { Auth.auth().currentUser?.uid }

    private var collectionRef: CollectionReference? {
        guard let uid else { return nil }
        return Firestore.firestore()
            .collection("users").document(uid)
            .collection("tastingRecords")
    }

    // MARK: - Init

    init(
        localRepository: LocalTastingNoteRepository,
        editingNote: TastingNote? = nil,
        initialPerfume: Perfume? = nil
    ) {
        self.localRepository = localRepository
        self.editingNote = editingNote
        if let editingNote {
            loadEditingNote(editingNote)
        } else if let initialPerfume {
            preloadPerfume(initialPerfume)
        }
    }

    // MARK: - Load

    private func loadEditingNote(_ note: TastingNote) {
        perfumeName = note.perfumeName
        brandName = note.brandName
        // 이전 영문 태그 → 한국어 마이그레이션
        mainAccords = note.mainAccords.map {
            kLegacyTagToKorean[$0] ?? PerfumeKoreanTranslator.korean(for: $0)
        }
        concentration = note.concentration ?? ""
        rating = note.rating
        // 이전 영문 무드태그 → 한국어 마이그레이션
        selectedMoodTags = Set(note.moodTags.map {
            kLegacyTagToKorean[$0] ?? $0
        })
        revisitDesire = note.revisitDesire
        memo = note.memo
        perfumeImageURL = note.perfumeImageURL
    }

    private func preloadPerfume(_ perfume: Perfume) {
        perfumeName = PerfumePresentationSupport.displayPerfumeName(perfume.name)
        brandName = PerfumePresentationSupport.displayBrand(perfume.brand)
        mainAccords = PerfumeKoreanTranslator.koreanAccords(for: perfume.mainAccords)
        concentration = perfume.concentration ?? ""
        perfumeImageURL = perfume.imageUrl
    }

    // MARK: - 태그 토글

    func toggleMoodTag(_ tag: String) {
        if selectedMoodTags.contains(tag) {
            selectedMoodTags.remove(tag)
        } else {
            selectedMoodTags.insert(tag)
        }
    }

    /// 다시 쓰고 싶은지 단일 선택 — 이미 선택된 태그를 탭하면 선택 해제
    func toggleRevisitDesire(_ tag: String) {
        revisitDesire = (revisitDesire == tag) ? nil : tag
    }

    // MARK: - 초기화

    func reset() {
        errorMessage = nil
        saveSuccess = false

        if let editingNote {
            loadEditingNote(editingNote)
        } else {
            perfumeName = ""
            brandName = ""
            mainAccords = []
            concentration = ""
            perfumeImageURL = nil
            rating = 0
            selectedMoodTags = []
            revisitDesire = nil
            memo = ""
        }
    }

    // MARK: - 저장

    func save() async {
        guard !isSaving else { return }
        guard canSave else { return }
        isSaving = true
        errorMessage = nil

        let now = Date()
        let note = TastingNote(
            id: editingNote?.id,
            perfumeName: perfumeName,
            brandName: brandName,
            mainAccords: mainAccords,
            concentration: concentration.isEmpty ? nil : concentration,
            rating: rating,
            moodTags: orderedMoodTags(from: selectedMoodTags),
            revisitDesire: revisitDesire,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines),
            perfumeImageURL: perfumeImageURL,
            createdAt: editingNote?.createdAt ?? now,
            updatedAt: now
        )

        do {
            let savedNote = try await localRepository.save(note)
            savedPerfumeName = savedNote.perfumeName
            saveSuccess = true
        } catch {
            errorMessage = AppStrings.ViewModelMessages.TastingNoteForm.saveFailed
        }
        isSaving = false
    }

    private func orderedMoodTags(from tags: Set<String>) -> [String] {
        tags.sorted {
            let li = allMoodTags.firstIndex(of: $0) ?? Int.max
            let ri = allMoodTags.firstIndex(of: $1) ?? Int.max
            return li < ri
        }
    }

    private func findDuplicateNote(in ref: CollectionReference) async throws -> TastingNoteDocument? {
        let snapshot = try await ref.getDocuments()
        let currentKey = duplicateKey(perfumeName: perfumeName, brandName: brandName)

        let matches: [TastingNoteDocument] = snapshot.documents.compactMap { document -> TastingNoteDocument? in
            guard var note = try? document.data(as: TastingNote.self),
                  duplicateKey(perfumeName: note.perfumeName, brandName: note.brandName) == currentKey else {
                return nil
            }
            note.id = document.documentID
            return TastingNoteDocument(id: document.documentID, note: note)
        }

        return matches
            .sorted { lhs, rhs in lhs.note.createdAt > rhs.note.createdAt }
            .first
    }

    private func duplicateKey(perfumeName: String, brandName: String) -> String {
        let normalizedName = perfumeName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let normalizedBrand = brandName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return "\(normalizedBrand)|\(normalizedName)"
    }

    private static func isKoreanScalar(_ scalar: UnicodeScalar) -> Bool {
        (0xAC00...0xD7A3).contains(Int(scalar.value))
    }

    private static func isEnglishScalar(_ scalar: UnicodeScalar) -> Bool {
        (0x41...0x5A).contains(Int(scalar.value)) ||
        (0x61...0x7A).contains(Int(scalar.value))
    }

    private static func isNumberScalar(_ scalar: UnicodeScalar) -> Bool {
        (0x30...0x39).contains(Int(scalar.value))
    }
}

private struct TastingNoteDocument {
    let id: String
    let note: TastingNote

    var createdAt: Date { note.createdAt }
}
