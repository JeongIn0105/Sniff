//
//  AppStateManager.swift
//  Sniff
//
//  Created by 이정인 on 4/16/26.
//

import Foundation
import Combine

final class AppStateManager: ObservableObject {
    @Published var state: AppState = .splash
}
