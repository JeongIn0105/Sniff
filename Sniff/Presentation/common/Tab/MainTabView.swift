//
//  MainTabView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Combine
import SwiftUI
import UIKit

extension Notification.Name {
    static let perfumeCollectionDidChange = Notification.Name("sniff.perfumeCollectionDidChange")
    static let tasteProfileDidChange = Notification.Name("sniff.tasteProfileDidChange")
}

enum MainTabSelection: Int, Hashable {
    case home = 0
    case search = 1
    case tastingNote = 2
    case my = 3
}

final class MainTabRouter: ObservableObject {
    static let shared = MainTabRouter()

    @Published var selectedTab: MainTabSelection = .home
    @Published private var resetTokens: [MainTabSelection: UUID] = [:]

    private init() {}

    func select(_ tab: MainTabSelection) {
        selectAndReset(tab)
    }

    func selectAndReset(_ tab: MainTabSelection) {
        selectedTab = tab
        reset(tab)
    }

    func reset(_ tab: MainTabSelection) {
        resetTokens[tab] = UUID()
    }

    func resetToken(for tab: MainTabSelection) -> UUID {
        resetTokens[tab] ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
}

struct MainTabView: View {
    @ObservedObject private var tabRouter = MainTabRouter.shared

    private var selectedTabBinding: Binding<MainTabSelection> {
        Binding(
            get: { tabRouter.selectedTab },
            set: { tabRouter.selectAndReset($0) }
        )
    }

    var body: some View {
        TabView(selection: selectedTabBinding) {
            HomeTabContainerView()
                .id(tabRouter.resetToken(for: .home))
                .ignoresSafeArea(.all, edges: .top)  // 상태바 영역까지 그라데이션 확장
                .tabItem {
                    Image(systemName: "house")
                    Text(AppStrings.AppShell.MainTab.home)
                }
                .tag(MainTabSelection.home)

            SearchTabContainerView()
                .id(tabRouter.resetToken(for: .search))
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text(AppStrings.AppShell.MainTab.search)
                }
                .tag(MainTabSelection.search)

            TastingNoteSceneFactory.makeListView()
                .id(tabRouter.resetToken(for: .tastingNote))
                .tabItem {
                    Image(systemName: "book.closed.fill")
                    Text(AppStrings.AppShell.MainTab.tastingNote)
                }
                .tag(MainTabSelection.tastingNote)

            MyTabContainerView()
                .id(tabRouter.resetToken(for: .my))
                .tabItem {
                    Image(systemName: "person.circle")
                    Text(AppStrings.AppShell.MainTab.my)
                }
                .tag(MainTabSelection.my)
        }
        .tint(.black)
        .background(MainTabResetObserver())
    }
}

private struct MainTabResetObserver: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            context.coordinator.attachIfNeeded(from: viewController)
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.attachIfNeeded(from: uiViewController)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UITabBarControllerDelegate {
        private weak var tabBarController: UITabBarController?

        func attachIfNeeded(from viewController: UIViewController) {
            guard let tabBarController = findTabBarController(from: viewController),
                  self.tabBarController !== tabBarController else { return }
            self.tabBarController = tabBarController
            tabBarController.delegate = self
        }

        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            guard let index = tabBarController.viewControllers?.firstIndex(of: viewController),
                  let tab = MainTabSelection(rawValue: index) else { return }
            MainTabRouter.shared.selectAndReset(tab)
        }

        private func findTabBarController(from viewController: UIViewController) -> UITabBarController? {
            var current: UIViewController? = viewController
            while let candidate = current {
                if let tabBarController = candidate as? UITabBarController {
                    return tabBarController
                }
                current = candidate.parent
            }
            guard let rootViewController = viewController.view.window?.rootViewController else { return nil }
            return findTabBarController(in: rootViewController)
        }

        private func findTabBarController(in viewController: UIViewController) -> UITabBarController? {
            if let tabBarController = viewController as? UITabBarController {
                return tabBarController
            }
            for child in viewController.children {
                if let tabBarController = findTabBarController(in: child) {
                    return tabBarController
                }
            }
            if let presentedViewController = viewController.presentedViewController {
                return findTabBarController(in: presentedViewController)
            }
            return nil
        }
    }
}

private struct HomeTabContainerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let homeViewController = HomeSceneFactory.makeViewController()
        let navigationController = UINavigationController(rootViewController: homeViewController)
        navigationController.navigationBar.isHidden = true
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

private struct SearchTabContainerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let searchViewController = SearchSceneFactory.makeSearchViewController()
        let navigationController = UINavigationController(rootViewController: searchViewController)
        navigationController.navigationBar.isHidden = true
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

private struct MyTabContainerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = MySceneFactory.makeViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.isHidden = true
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

private struct PlaceholderTabView: View {
    let title: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .semibold))
                Text(AppStrings.AppShell.MainTab.placeholder(title))
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }
}
