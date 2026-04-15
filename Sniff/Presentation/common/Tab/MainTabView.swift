//
//  MainTabView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Text("홈")
                .tabItem {
                    Image(systemName: "house")
                    Text("홈")
                }
            Text("검색")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("검색")
                }
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
    }
}
