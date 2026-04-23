//
//  MainTabView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
import UIKit

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeTabContainerView()
                .tabItem {
                    Image(systemName: "house")
                    Text(AppStrings.AppShell.MainTab.home)
                }

            SearchTabContainerView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text(AppStrings.AppShell.MainTab.search)
                }

            TastingNoteSceneFactory.makeListView()
                .tabItem {
                    Image(systemName: "book.closed")
                    Text(AppStrings.AppShell.MainTab.tastingNote)
                }

            MyTabContainerView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text(AppStrings.AppShell.MainTab.my)
                }
        }
        .tint(.black)
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
