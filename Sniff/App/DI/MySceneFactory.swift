//
//  MySceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.18.
//

import Foundation

enum MySceneFactory {
    static func makeViewController() -> LikePerfumesViewController {
        LikePerfumesViewController(collectionRepository: CollectionRepository())
    }
}
