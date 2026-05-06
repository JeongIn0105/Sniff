//
//  FilterViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//

import Foundation

final class FilterViewModel {

    let currentFilter: SearchFilter
    var currentPerfumes: [Perfume] = []

    init(initialFilter: SearchFilter = SearchFilter()) {
        var sanitizedFilter = initialFilter
        sanitizedFilter.moodTags = []
        self.currentFilter = sanitizedFilter
    }
}
