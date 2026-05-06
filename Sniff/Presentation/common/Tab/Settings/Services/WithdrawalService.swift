//
//  WithdrawalService.swift
//  Sniff
//

import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import Foundation
import UIKit

enum WithdrawalReauthenticationProvider: Equatable {
    case apple
    case google
    case unsupported
}

enum WithdrawalServiceError: Error, Equatable {
    case requiresReauthentication(WithdrawalReauthenticationProvider)
}

@MainActor
protocol WithdrawalServiceType {
    func withdrawAccount() async throws
    func reauthenticateWithApple(presentationAnchor: ASPresentationAnchor) async throws
    func reauthenticateWithGoogle(presentingWindow: UIWindow) async throws
    func resetReauthentication()
    func isRecentLoginError(_ error: Error) -> Bool
}

@MainActor
final class WithdrawalService: WithdrawalServiceType {

    private let authService: AuthServiceType
    private let appleSignInHelper: AppleSignInHelper
    private let googleSignInHelper: GoogleSignInHelper
    private let coreDataStack: CoreDataStack
    private let database: Firestore
    private var didReauthenticateForWithdrawal = false

    init(
        authService: AuthServiceType,
        appleSignInHelper: AppleSignInHelper,
        googleSignInHelper: GoogleSignInHelper,
        coreDataStack: CoreDataStack,
        database: Firestore = Firestore.firestore()
    ) {
        self.authService = authService
        self.appleSignInHelper = appleSignInHelper
        self.googleSignInHelper = googleSignInHelper
        self.coreDataStack = coreDataStack
        self.database = database
    }

    func withdrawAccount() async throws {
        guard isRecentlySignedIn || didReauthenticateForWithdrawal else {
            throw WithdrawalServiceError.requiresReauthentication(currentReauthenticationProvider)
        }

        await deleteSubcollectionsSilently()
        try await deleteUserDocument()
        try await authService.deleteCurrentUser()
        try? coreDataStack.deleteAllTastingNotes()
    }

    func reauthenticateWithApple(presentationAnchor: ASPresentationAnchor) async throws {
        let payload = try await startAppleSignIn(presentationAnchor: presentationAnchor)
        try await authService.reauthenticateWithApple(
            identityToken: payload.identityToken,
            rawNonce: payload.rawNonce
        )
        didReauthenticateForWithdrawal = true
    }

    func reauthenticateWithGoogle(presentingWindow: UIWindow) async throws {
        let payload = try await googleSignInHelper.startSignIn(presentingWindow: presentingWindow)
        try await authService.reauthenticateWithGoogle(
            idToken: payload.idToken,
            accessToken: payload.accessToken
        )
        didReauthenticateForWithdrawal = true
    }

    func resetReauthentication() {
        didReauthenticateForWithdrawal = false
    }

    func isRecentLoginError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return AuthErrorCode.Code(rawValue: nsError.code) == .requiresRecentLogin
    }
}

private extension WithdrawalService {

    var isRecentlySignedIn: Bool {
        guard let lastSignInDate = Auth.auth().currentUser?.metadata.lastSignInDate else { return false }
        return Date().timeIntervalSince(lastSignInDate) < 300
    }

    var currentReauthenticationProvider: WithdrawalReauthenticationProvider {
        let providerIDs = Auth.auth().currentUser?.providerData.map(\.providerID) ?? []
        if providerIDs.contains("apple.com") { return .apple }
        if providerIDs.contains("google.com") { return .google }
        return .unsupported
    }

    func startAppleSignIn(presentationAnchor: ASPresentationAnchor) async throws -> AppleSignInPayload {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AppleSignInPayload, Error>) in
            appleSignInHelper.startSignIn(presentationAnchor: presentationAnchor) { result in
                continuation.resume(with: result)
            }
        }
    }

    func deleteUserDocument() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreServiceError.missingAuthenticatedUser
        }
        try await database
            .collection("users")
            .document(uid)
            .delete()
    }

    func deleteSubcollectionsSilently() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let userRef = database.collection("users").document(uid)

        for subcollection in ["collection", "likes", "tastingRecords", "profileHistory"] {
            guard let snapshot = try? await userRef.collection(subcollection).getDocuments() else { continue }
            guard !snapshot.documents.isEmpty else { continue }
            let batch = database.batch()
            snapshot.documents.forEach { batch.deleteDocument($0.reference) }
            try? await batch.commit()
        }
    }
}
