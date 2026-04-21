//
//  RxSwift+Async.swift
//  Sniff
//
//  Created by Codex on 2026.04.20.
//

import Foundation
@preconcurrency import RxSwift

private actor DisposableBox {
    private var disposable: Disposable?

    func set(_ disposable: Disposable) {
        self.disposable = disposable
    }

    func dispose() {
        disposable?.dispose()
    }
}

extension PrimitiveSequence where Trait == SingleTrait {
    func async() async throws -> Element {
        let box = DisposableBox()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let disposable = self.subscribe(
                    onSuccess: { value in
                        continuation.resume(returning: value)
                    },
                    onFailure: { error in
                        continuation.resume(throwing: error)
                    }
                )
                Task {
                    await box.set(disposable)
                }
            }
        } onCancel: {
            Task {
                await box.dispose()
            }
        }
    }
}
