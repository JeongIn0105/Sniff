//
//  HomeQuickAction.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//

import Foundation

enum HomeQuickActionType {
    case perfumeRegister
    case tastingNote
    case report
}

struct HomeQuickAction {
    let type: HomeQuickActionType
    let title: String
    let systemImageName: String
}
