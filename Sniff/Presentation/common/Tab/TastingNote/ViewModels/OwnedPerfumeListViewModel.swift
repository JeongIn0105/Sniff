//
//  OwnedPerfumeListViewModel.swift
//  Sniff
//

// MARK: - 보유 향수 목록 뷰모델
import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class OwnedPerfumeListViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var perfumes: [CollectedPerfume] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Computed

    var isEmpty: Bool { perfumes.isEmpty }

    // MARK: - Private

    private var listenerRegistration: ListenerRegistration?

    private var uid: String? { Auth.auth().currentUser?.uid }

    private var collectionRef: CollectionReference? {
        guard let uid else { return nil }
        return Firestore.firestore()
            .collection("users").document(uid)
            .collection("collection")
    }

    // MARK: - Init / Deinit

    init() { fetchPerfumes() }

    deinit { listenerRegistration?.remove() }

    // MARK: - 목록 실시간 조회

    func fetchPerfumes() {
        guard let ref = collectionRef else { return }
        isLoading = true

        listenerRegistration = ref
            .order(by: "addedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    let nsError = error as NSError
                    // Firestore 권한 에러(코드 7)는 규칙 미설정 상태이므로 빈 목록으로 처리
                    if nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 7 {
                        self.perfumes = []
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    return
                }
                self.perfumes = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard
                        let name  = data["name"]  as? String,
                        let brand = data["brand"] as? String
                    else { return nil }
                    let ts = data["addedAt"] as? Timestamp
                    return CollectedPerfume(
                        id: doc.documentID,
                        name: name,
                        brand: brand,
                        scentFamily: data["scentFamily"] as? String,
                        scentFamily2: data["scentFamily2"] as? String,
                        imageURL: data["imageURL"] as? String,
                        createdAt: ts?.dateValue()
                    )
                } ?? []
            }
    }

    func clearError() { errorMessage = nil }
}
