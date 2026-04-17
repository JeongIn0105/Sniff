//
//  NicknameValidator.swift
//  Sniff
//
//  Created by Codex on 2026.04.15.
//

import Foundation

struct NicknameValidator {
    func sanitize(_ value: String) -> String {
        String(value.prefix(10))
    }

    func isValidFormat(_ nickname: String) -> Bool {
        let pattern = "^[A-Za-z0-9가-힣]{2,10}$"
        return nickname.range(of: pattern, options: .regularExpression) != nil
    }
}
