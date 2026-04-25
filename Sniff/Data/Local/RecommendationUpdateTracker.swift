//
//  RecommendationUpdateTracker.swift
//  Sniff
//

import Foundation

final class RecommendationUpdateTracker {

    private let defaults = UserDefaults.standard
    private let timestampsKey = "sniff.recommendation.updateTimestamps.v1"
    private static let dailyLimit = 2

    var todayUpdateCount: Int {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return storedTimestamps().filter { $0 >= startOfToday }.count
    }

    /// 이번 홈 로드가 공식 업데이트로 기록될 수 있는지 판단.
    /// - count == 0: 당일 첫 업데이트 → 항상 허용 (온보딩 직후 포함)
    /// - count == 1: 두 번째 업데이트 → 조건 충족 시만 허용
    /// - count >= 2: 당일 한도 소진 → 불허
    func canRecord(collectionCount: Int, tastingCount: Int) -> Bool {
        let count = todayUpdateCount
        guard count < Self.dailyLimit else { return false }
        if count == 0 { return true }
        return (collectionCount + tastingCount >= 3) || (tastingCount >= 5)
    }

    func recordUpdate() {
        var timestamps = storedTimestamps()
        timestamps.append(Date())
        let cutoff = Calendar.current.startOfDay(for: Date()).addingTimeInterval(-24 * 3600)
        timestamps = timestamps.filter { $0 >= cutoff }
        guard let data = try? JSONEncoder().encode(timestamps) else { return }
        defaults.set(data, forKey: timestampsKey)
    }

    private func storedTimestamps() -> [Date] {
        guard
            let data = defaults.data(forKey: timestampsKey),
            let timestamps = try? JSONDecoder().decode([Date].self, from: data)
        else { return [] }
        return timestamps
    }
}
