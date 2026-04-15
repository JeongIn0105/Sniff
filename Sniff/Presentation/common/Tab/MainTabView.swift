<<<<<<< HEAD
//
//  MainTabView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
=======
    //
    //  MainTabView.swift
    //  Sniff
    //
    //  Created by t2025-m0239 on 2026.04.13.
    //

import SwiftUI
import UIKit
>>>>>>> origin/main

struct MainTabView: View {
    var body: some View {
        TabView {
<<<<<<< HEAD
            Text("홈")
=======
            HomeTabContainerView()
>>>>>>> origin/main
                .tabItem {
                    Image(systemName: "house")
                    Text("홈")
                }
<<<<<<< HEAD
            Text("검색")
=======

            PlaceholderTabView(title: "검색")
>>>>>>> origin/main
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("검색")
                }
<<<<<<< HEAD
            Text("시향기")
                .tabItem {
                    Image(systemName: "note.text")
                    Text("시향기")
                }
            Text("MY")
                .tabItem {
                    Image(systemName: "person")
                    Text("MY")
                }
        }
        .accentColor(.black)
=======

            PlaceholderTabView(title: "시향 기록")
                .tabItem {
                    Image(systemName: "book.closed")
                    Text("시향 기록")
                }

            PlaceholderTabView(title: "MY")
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("MY")
                }
        }
        .tint(.black)
    }
}

private struct HomeTabContainerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let homeViewController = HomeViewController()
        let navigationController = UINavigationController(rootViewController: homeViewController)
        navigationController.navigationBar.isHidden = true
        navigationController.tabBarItem.title = "홈"
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
                Text("\(title) 화면 준비 중")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
>>>>>>> origin/main
    }
}
