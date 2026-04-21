//
//  MyPageSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.20.
//

import Foundation
import SwiftUI

enum MyPageSceneFactory {

    @MainActor
    static func makeView() -> MyPageView {
        makeView(dependencyContainer: AppDependencyContainer())
    }

    @MainActor
    static func makeView(
        dependencyContainer: AppDependencyContainer
    ) -> MyPageView {
        MyPageView(viewModel: dependencyContainer.makeMyPageViewModel())
    }

    @MainActor
    static func makeViewController() -> UIHostingController<MyPageView> {
        makeViewController(dependencyContainer: AppDependencyContainer())
    }

    @MainActor
    static func makeViewController(
        dependencyContainer: AppDependencyContainer
    ) -> UIHostingController<MyPageView> {
        UIHostingController(rootView: makeView(dependencyContainer: dependencyContainer))
    }
}
