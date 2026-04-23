//
//  LocalTastingNoteEntity.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import CoreData
import Foundation

@objc(LocalTastingNoteEntity)
final class LocalTastingNoteEntity: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var remoteID: String?
    @NSManaged var perfumeName: String
    @NSManaged var brandName: String
    @NSManaged var mainAccordsJSON: String
    @NSManaged var concentration: String?
    @NSManaged var rating: Int16
    @NSManaged var moodTagsJSON: String
    @NSManaged var revisitDesire: String?
    @NSManaged var memo: String
    @NSManaged var perfumeImageURL: String?
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var syncStatus: String
    @NSManaged var isDeletedPending: Bool
}

extension LocalTastingNoteEntity {
    static func fetchRequest() -> NSFetchRequest<LocalTastingNoteEntity> {
        NSFetchRequest<LocalTastingNoteEntity>(entityName: "LocalTastingNoteEntity")
    }
}
