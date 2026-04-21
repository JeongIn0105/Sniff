//
//  MySceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.18.
//

import Foundation
import UIKit

enum MySceneFactory {

    @MainActor
    static func makeViewController() -> UIViewController {
        makeViewController(dependencyContainer: AppDependencyContainer())
    }

    @MainActor
    static func makeViewController(
        dependencyContainer: AppDependencyContainer
    ) -> UIViewController {
        MyPageSceneFactory.makeViewController(dependencyContainer: dependencyContainer)
    }
}
