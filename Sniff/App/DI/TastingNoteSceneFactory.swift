//
//  TastingNoteSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.20.
//

import Foundation
import SwiftUI

enum TastingNoteSceneFactory {

    @MainActor
    static func makeListView() -> TastingNoteView {
        makeListView(dependencyContainer: AppDependencyContainer())
    }

    @MainActor
    static func makeListView(
        perfumeScope: TastingNotePerfumeScope?
    ) -> TastingNoteView {
        makeListView(
            perfumeScope: perfumeScope,
            dependencyContainer: AppDependencyContainer()
        )
    }

    @MainActor
    static func makeListView(
        perfumeScope: TastingNotePerfumeScope? = nil,
        dependencyContainer: AppDependencyContainer
    ) -> TastingNoteView {
        TastingNoteView(viewModel: dependencyContainer.makeTastingNoteViewModel(perfumeScope: perfumeScope))
    }

    @MainActor
    static func makeListView(
        dependencyContainer: AppDependencyContainer
    ) -> TastingNoteView {
        makeListView(perfumeScope: nil, dependencyContainer: dependencyContainer)
    }

    @MainActor
    static func makeOwnedPerfumeListView() -> OwnedPerfumeListView {
        makeOwnedPerfumeListView(dependencyContainer: AppDependencyContainer())
    }

    @MainActor
    static func makeOwnedPerfumeListView(
        dependencyContainer: AppDependencyContainer
    ) -> OwnedPerfumeListView {
        OwnedPerfumeListView(viewModel: dependencyContainer.makeOwnedPerfumeListViewModel())
    }

    @MainActor
    static func makeLikedPerfumeListView() -> LikedPerfumeListView {
        makeLikedPerfumeListView(dependencyContainer: AppDependencyContainer())
    }

    @MainActor
    static func makeLikedPerfumeListView(
        dependencyContainer: AppDependencyContainer
    ) -> LikedPerfumeListView {
        LikedPerfumeListView(viewModel: dependencyContainer.makeLikedPerfumeListViewModel())
    }

    @MainActor
    static func makeFormView(
        editingNote: TastingNote? = nil,
        initialPerfume: Perfume? = nil,
        isOwnedPerfumeContext: Bool = false,
        onSaveSuccess: @escaping (String) -> Void = { _ in }
    ) -> TastingNoteFormView {
        makeFormView(
            editingNote: editingNote,
            initialPerfume: initialPerfume,
            isOwnedPerfumeContext: isOwnedPerfumeContext,
            dependencyContainer: AppDependencyContainer(),
            onSaveSuccess: onSaveSuccess
        )
    }

    @MainActor
    static func makeFormView(
        editingNote: TastingNote? = nil,
        initialPerfume: Perfume? = nil,
        isOwnedPerfumeContext: Bool = false,
        dependencyContainer: AppDependencyContainer,
        onSaveSuccess: @escaping (String) -> Void = { _ in }
    ) -> TastingNoteFormView {
        TastingNoteFormView(
            viewModel: dependencyContainer.makeTastingNoteFormViewModel(
                editingNote: editingNote,
                initialPerfume: initialPerfume,
                isOwnedPerfumeContext: isOwnedPerfumeContext
            ),
            onSaveSuccess: onSaveSuccess
        )
    }
}
