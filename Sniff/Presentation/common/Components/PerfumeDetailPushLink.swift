//
//  PerfumeDetailPushLink.swift
//  Sniff
//

import SwiftUI
import UIKit

struct PerfumeDetailPushLink<Label: View>: View {
    private let perfume: Perfume
    private let label: () -> Label
    @State private var pendingPerfume: Perfume?

    init(
        perfume: Perfume,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.perfume = perfume
        self.label = label
    }

    var body: some View {
        Button {
            pendingPerfume = perfume
        } label: {
            label()
        }
        .background(PerfumeDetailPushPresenter(perfume: $pendingPerfume))
    }
}

private struct PerfumeDetailPushPresenter: UIViewControllerRepresentable {
    @Binding var perfume: Perfume?

    func makeUIViewController(context: Context) -> PerfumeDetailPushPresenterViewController {
        PerfumeDetailPushPresenterViewController()
    }

    func updateUIViewController(
        _ uiViewController: PerfumeDetailPushPresenterViewController,
        context: Context
    ) {
        guard let perfume else { return }
        uiViewController.pushDetailIfPossible(perfume: perfume) {
            self.perfume = nil
        }
    }
}

private final class PerfumeDetailPushPresenterViewController: UIViewController {
    private var pendingPerfume: Perfume?
    private var isPushScheduled = false

    func pushDetailIfPossible(perfume: Perfume, completion: @escaping () -> Void) {
        pendingPerfume = perfume
        guard !isPushScheduled else { return }

        isPushScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isPushScheduled = false
            guard let perfume = self.pendingPerfume else { return }
            self.pendingPerfume = nil
            completion()

            guard let navigationController = NavigationControllerFinder.find(from: self) else { return }
            let detailViewController = PerfumeDetailSceneFactory.makeViewController(perfume: perfume)
            navigationController.pushViewController(detailViewController, animated: true)
        }
    }
}

private enum NavigationControllerFinder {
    static func find(from viewController: UIViewController) -> UINavigationController? {
        if let navigationController = viewController.navigationController {
            return navigationController
        }

        var parentController = viewController.parent
        while let controller = parentController {
            if let navigationController = controller as? UINavigationController {
                return navigationController
            }
            if let navigationController = controller.navigationController {
                return navigationController
            }
            parentController = controller.parent
        }

        if let navigationController = navigationControllerFromResponderChain(startingAt: viewController.view) {
            return navigationController
        }

        guard let rootViewController = viewController.view.window?.rootViewController else {
            return nil
        }
        return find(in: rootViewController)
    }

    private static func navigationControllerFromResponderChain(startingAt view: UIView) -> UINavigationController? {
        var responder = view.next
        while let currentResponder = responder {
            if let navigationController = currentResponder as? UINavigationController {
                return navigationController
            }
            if let viewController = currentResponder as? UIViewController,
               let navigationController = viewController.navigationController {
                return navigationController
            }
            responder = currentResponder.next
        }

        return nil
    }

    private static func find(in viewController: UIViewController) -> UINavigationController? {
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        if let navigationController = viewController.navigationController {
            return navigationController
        }
        if let presentedViewController = viewController.presentedViewController,
           let navigationController = find(in: presentedViewController) {
            return navigationController
        }
        for childViewController in viewController.children {
            if let navigationController = find(in: childViewController) {
                return navigationController
            }
        }
        return nil
    }
}
