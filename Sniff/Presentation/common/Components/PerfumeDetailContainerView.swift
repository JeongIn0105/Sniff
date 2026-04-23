//
//  PerfumeDetailContainerView.swift
//  Sniff
//

import SwiftUI

struct PerfumeDetailContainerView: UIViewControllerRepresentable {
    private let source: Source

    private enum Source {
        case perfumeId(String)
        case perfume(Perfume)
    }

    init(perfumeId: String) {
        self.source = .perfumeId(perfumeId)
    }

    init(perfume: Perfume) {
        self.source = .perfume(perfume)
    }

    func makeUIViewController(context: Context) -> PerfumeDetailViewController {
        switch source {
        case let .perfumeId(perfumeId):
            return PerfumeDetailSceneFactory.makeViewController(perfumeId: perfumeId)
        case let .perfume(perfume):
            return PerfumeDetailSceneFactory.makeViewController(perfume: perfume)
        }
    }

    func updateUIViewController(_ uiViewController: PerfumeDetailViewController, context: Context) {}
}
