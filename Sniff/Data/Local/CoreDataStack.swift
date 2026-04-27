//
//  CoreDataStack.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import CoreData
import Foundation

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Sniff")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.persistentStoreDescriptions.first?.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions.first?.shouldInferMappingModelAutomatically = true
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("CoreData load failed: \(error.localizedDescription)")
            }
        }
    }

    func saveIfNeeded() throws {
        guard viewContext.hasChanges else { return }
        try viewContext.save()
    }

    /// 로컬 Core Data에 저장된 모든 시향기 데이터를 삭제합니다.
    /// 회원 탈퇴 시 기기에 남은 개인 데이터를 완전히 지우기 위해 호출합니다.
    func deleteAllTastingNotes() throws {
        let request: NSFetchRequest<NSFetchRequestResult> = LocalTastingNoteEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        deleteRequest.resultType = .resultTypeObjectIDs

        let result = try viewContext.execute(deleteRequest) as? NSBatchDeleteResult
        let objectIDs = result?.result as? [NSManagedObjectID] ?? []

        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
            into: [viewContext]
        )
    }
}
