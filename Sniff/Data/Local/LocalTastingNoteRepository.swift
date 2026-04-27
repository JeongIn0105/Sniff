//
//  LocalTastingNoteRepository.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import CoreData
import FirebaseAuth
import FirebaseFirestore
import Foundation

extension Notification.Name {
    static let tastingNotesDidChange = Notification.Name("sniff.tastingNotesDidChange")
}

enum TastingNoteSyncStatus: String {
    case pending
    case synced
    case failed
    case pendingDelete
}

@MainActor
final class LocalTastingNoteRepository {
    private enum NarrativeRefreshRule {
        static let minimumRecordCount = 5
        static let minimumMemoLength = 20
    }

    private let coreDataStack: CoreDataStack
    private let database: Firestore
    private let userTasteRepository: UserTasteRepositoryType
    /// Gemini 취향 재분석 호출 횟수를 하루 2회로 제한합니다.
    private let recommendationTracker = RecommendationUpdateTracker()

    private var context: NSManagedObjectContext {
        coreDataStack.viewContext
    }

    private var collectionRef: CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return database
            .collection("users").document(uid)
            .collection("tastingRecords")
    }

    init(
        coreDataStack: CoreDataStack,
        database: Firestore = .firestore(),
        userTasteRepository: UserTasteRepositoryType? = nil
    ) {
        self.coreDataStack = coreDataStack
        self.database = database
        self.userTasteRepository = userTasteRepository ?? UserTasteRepository()
    }

    func loadNotes() throws -> [TastingNote] {
        let request = LocalTastingNoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isDeletedPending == NO")
        request.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(LocalTastingNoteEntity.createdAt), ascending: false)
        ]

        return try context.fetch(request).map(makeTastingNote)
    }

    @discardableResult
    func save(_ note: TastingNote) async throws -> TastingNote {
        let entity = try entityForSaving(note)
        apply(note, to: entity)
        entity.syncStatus = TastingNoteSyncStatus.pending.rawValue
        entity.isDeletedPending = false
        try coreDataStack.saveIfNeeded()
        notifyChange()

        await syncPendingChanges()
        return makeTastingNote(entity)
    }

    func delete(_ note: TastingNote) async throws {
        guard let id = note.id else { return }
        guard let entity = try findEntity(id: id) else { return }

        if entity.remoteID == nil {
            context.delete(entity)
            try coreDataStack.saveIfNeeded()
            notifyChange()
            return
        }

        entity.isDeletedPending = true
        entity.syncStatus = TastingNoteSyncStatus.pendingDelete.rawValue
        try coreDataStack.saveIfNeeded()
        notifyChange()
        await syncPendingChanges()
    }

    func delete(ids: Set<String>) async throws {
        for id in ids {
            guard let entity = try findEntity(id: id) else { continue }

            if entity.remoteID == nil {
                context.delete(entity)
            } else {
                entity.isDeletedPending = true
                entity.syncStatus = TastingNoteSyncStatus.pendingDelete.rawValue
            }
        }

        try coreDataStack.saveIfNeeded()
        notifyChange()
        await syncPendingChanges()
    }

    func refreshFromRemote() async {
        guard let ref = collectionRef else { return }

        do {
            let snapshot = try await ref
                .order(by: "createdAt", descending: true)
                .getDocuments()

            for document in snapshot.documents {
                guard var note = try? document.data(as: TastingNote.self) else { continue }
                note.id = document.documentID
                let entity = try findEntity(remoteID: document.documentID)
                    ?? findEntity(id: document.documentID)
                    ?? LocalTastingNoteEntity(context: context)

                if currentID(for: entity).isEmpty {
                    entity.id = document.documentID
                }

                apply(note, to: entity)
                entity.remoteID = document.documentID
                entity.syncStatus = TastingNoteSyncStatus.synced.rawValue
                entity.isDeletedPending = false
            }

            try coreDataStack.saveIfNeeded()
            notifyChange()
        } catch {
            // 원격 동기화 실패 시 로컬 데이터는 그대로 사용한다.
        }
    }

    func syncPendingChanges() async {
        guard let ref = collectionRef else { return }

        do {
            let request = LocalTastingNoteEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "syncStatus IN %@",
                [
                    TastingNoteSyncStatus.pending.rawValue,
                    TastingNoteSyncStatus.failed.rawValue,
                    TastingNoteSyncStatus.pendingDelete.rawValue
                ]
            )

            let entities = try context.fetch(request)

            for entity in entities {
                if entity.isDeletedPending || entity.syncStatus == TastingNoteSyncStatus.pendingDelete.rawValue {
                    try await syncDelete(entity, ref: ref)
                } else {
                    try await syncUpsert(entity, ref: ref)
                }
            }

            try coreDataStack.saveIfNeeded()
            notifyChange()
            await refreshNarrativeIfNeeded()
        } catch {
            markPendingEntitiesAsFailed()
            try? coreDataStack.saveIfNeeded()
        }
    }

    // MARK: - Private

    private func entityForSaving(_ note: TastingNote) throws -> LocalTastingNoteEntity {
        if let id = note.id, let existing = try findEntity(id: id) {
            return existing
        }

        if let remoteID = note.id, let existing = try findEntity(remoteID: remoteID) {
            return existing
        }

        let entity = LocalTastingNoteEntity(context: context)
        entity.id = note.id ?? UUID().uuidString
        return entity
    }

    private func findEntity(id: String) throws -> LocalTastingNoteEntity? {
        let request = LocalTastingNoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func findEntity(remoteID: String) throws -> LocalTastingNoteEntity? {
        let request = LocalTastingNoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == %@", remoteID)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func syncUpsert(_ entity: LocalTastingNoteEntity, ref: CollectionReference) async throws {
        let note = makeTastingNote(entity)
        let documentRef: DocumentReference

        if let remoteID = entity.remoteID, !remoteID.isEmpty {
            documentRef = ref.document(remoteID)
        } else {
            documentRef = ref.document()
            entity.remoteID = documentRef.documentID
        }

        var remoteNote = note
        remoteNote.id = entity.remoteID
        try documentRef.setData(from: remoteNote)
        entity.syncStatus = TastingNoteSyncStatus.synced.rawValue
    }

    private func syncDelete(_ entity: LocalTastingNoteEntity, ref: CollectionReference) async throws {
        if let remoteID = entity.remoteID, !remoteID.isEmpty {
            try await ref.document(remoteID).delete()
        }
        context.delete(entity)
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .tastingNotesDidChange, object: nil)
    }

    private func refreshNarrativeIfNeeded() async {
        guard let records = try? await FirestoreService.shared.fetchTastingRecords() else { return }
        guard shouldRefreshNarrative(with: records) else { return }

        // 하루 최대 2회까지만 Gemini 취향 재분석을 호출합니다.
        // 시향 기록을 자주 수정하더라도 불필요한 API 비용이 발생하지 않습니다.
        guard recommendationTracker.canRecord(
            collectionCount: 0,
            tastingCount: records.count
        ) else { return }

        if (try? await userTasteRepository.reanalyzeTasteFromHistory()) != nil {
            recommendationTracker.recordUpdate()
        }
    }

    private func shouldRefreshNarrative(with records: [TastingRecord]) -> Bool {
        guard records.count >= NarrativeRefreshRule.minimumRecordCount else { return false }

        return records.contains { record in
            let memoLength = record.memo?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .count ?? 0
            return memoLength >= NarrativeRefreshRule.minimumMemoLength
        }
    }

    private func markPendingEntitiesAsFailed() {
        let request = LocalTastingNoteEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "syncStatus IN %@",
            [
                TastingNoteSyncStatus.pending.rawValue,
                TastingNoteSyncStatus.pendingDelete.rawValue
            ]
        )

        guard let entities = try? context.fetch(request) else { return }
        entities.forEach { $0.syncStatus = TastingNoteSyncStatus.failed.rawValue }
    }

    private func apply(_ note: TastingNote, to entity: LocalTastingNoteEntity) {
        if currentID(for: entity).isEmpty {
            entity.id = note.id ?? UUID().uuidString
        }

        entity.perfumeName = note.perfumeName
        entity.brandName = note.brandName
        entity.mainAccordsJSON = encodeStringArray(note.mainAccords)
        entity.concentration = note.concentration
        entity.rating = Int16(note.rating)
        entity.moodTagsJSON = encodeStringArray(note.moodTags)
        entity.revisitDesire = note.revisitDesire
        entity.memo = note.memo
        entity.perfumeImageURL = note.perfumeImageURL
        entity.createdAt = note.createdAt
        entity.updatedAt = note.updatedAt
    }

    private func makeTastingNote(_ entity: LocalTastingNoteEntity) -> TastingNote {
        TastingNote(
            id: entity.id,
            perfumeName: entity.perfumeName,
            brandName: entity.brandName,
            mainAccords: decodeStringArray(entity.mainAccordsJSON),
            concentration: entity.concentration,
            rating: Int(entity.rating),
            moodTags: decodeStringArray(entity.moodTagsJSON),
            revisitDesire: entity.revisitDesire,
            memo: entity.memo,
            perfumeImageURL: entity.perfumeImageURL,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    private func encodeStringArray(_ values: [String]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    private func decodeStringArray(_ value: String) -> [String] {
        guard let data = value.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return decoded
    }

    private func currentID(for entity: LocalTastingNoteEntity) -> String {
        (entity.value(forKey: #keyPath(LocalTastingNoteEntity.id)) as? String) ?? ""
    }
}
