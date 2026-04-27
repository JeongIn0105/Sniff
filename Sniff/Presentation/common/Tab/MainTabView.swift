//
//  MainTabView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
import UIKit

extension Notification.Name {
    static let mainTabSelectionRequested = Notification.Name("sniff.mainTabSelectionRequested")
    static let perfumeCollectionDidChange = Notification.Name("sniff.perfumeCollectionDidChange")
}

enum MainTabSelection: Int, Hashable {
    case home = 0
    case search = 1
    case tastingNote = 2
    case my = 3
}

struct MainTabView: View {
    @State private var selectedTab: MainTabSelection = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabContainerView()
                .tabItem {
                    Image(systemName: "house")
                    Text(AppStrings.AppShell.MainTab.home)
                }
                .tag(MainTabSelection.home)

            SearchTabContainerView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text(AppStrings.AppShell.MainTab.search)
                }
                .tag(MainTabSelection.search)

            TastingNoteSceneFactory.makeListView()
                .tabItem {
                    Image(systemName: "book.closed.fill")
                    Text(AppStrings.AppShell.MainTab.tastingNote)
                }
                .tag(MainTabSelection.tastingNote)

            MyTabContainerView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text(AppStrings.AppShell.MainTab.my)
                }
                .tag(MainTabSelection.my)
        }
        .tint(.black)
        .onReceive(NotificationCenter.default.publisher(for: .mainTabSelectionRequested)) { notification in
            guard
                let rawValue = notification.object as? Int,
                let tab = MainTabSelection(rawValue: rawValue)
            else { return }

            selectedTab = tab
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
