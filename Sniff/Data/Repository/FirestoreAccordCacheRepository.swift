//
//  FirestoreAccordCacheRepository.swift
//  Sniff
//
//  Created by OpenAI Codex on 2026.04.29.
//

import Foundation
import FirebaseFirestore
import RxSwift

nonisolated final class FirestoreAccordCacheRepository: AccordCacheRepository {
    private let database: Firestore

    init(database: Firestore = Firestore.firestore()) {
        self.database = database
    }

    func fetch(accord: String) -> Single<SubFamily?> {
        Single.create { [weak self] single in
            guard let self else {
                single(.success(nil))
                return Disposables.create()
            }

            self.document(for: accord).getDocument { snapshot, _ in
                guard
                    let data = snapshot?.data(),
                    let subFamilyKey = data["subFamily"] as? String
                else {
                    single(.success(nil))
                    return
                }

                single(.success(SubFamily(englishKey: subFamilyKey)))
            }

            return Disposables.create()
        }
    }

    func save(accord: String, subFamily: SubFamily, confidence: Double) {
        let data: [String: Any] = [
            "accord": normalizedAccordName(accord),
            "subFamily": subFamily.englishKey,
            "confidence": confidence,
            "source": "gemini",
            "updatedAt": FieldValue.serverTimestamp(),
            "createdAt": FieldValue.serverTimestamp()
        ]

        document(for: accord).setData(data, merge: true)
    }

    private func document(for accord: String) -> DocumentReference {
        database.collection("accordCache").document(documentID(for: accord))
    }

    private func documentID(for accord: String) -> String {
        normalizedAccordName(accord)
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
    }

    private func normalizedAccordName(_ accord: String) -> String {
        accord
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }
}
