//
//  SplashView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(white: 0.17)
                .ignoresSafeArea()

            Text("킁킁")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
