//
//  CollectionUsageLimiter.swift
//  Sniff
//

import Foundation

enum CollectionUsageLimitError: LocalizedError {
    case monthlyCollectionLimitReached
    case dailyLikeLimitReached
    case totalLikeLimitReached

    var errorDescription: String? {
        switch self {
        case .monthlyCollectionLimitReached:
            return AppStrings.CollectionUsageLimits.monthlyCollectionLimitReached
        case .dailyLikeLimitReached:
            return AppStrings.CollectionUsageLimits.dailyLikeLimitReached
        case .totalLikeLimitReached:
            return AppStrings.CollectionUsageLimits.totalLikeLimitReached
        }
    }
}

final class CollectionUsageLimiter {
    static let shared = CollectionUsageLimiter()

    private enum Limit {
        static let monthlyCollectionChanges = 5
        static let dailyLikes = 10
        static let totalLikes = 100
    }

    private enum Key {
        static let collectionMonth = "collectionUsageLimiter.collectionMonth"
        static let collectionCount = "collectionUsageLimiter.collectionCount"
        static let likeDay = "collectionUsageLimiter.likeDay"
        static let likeCount = "collectionUsageLimiter.likeCount"
    }

    private let defaults: UserDefaults
    private let lock = NSLock()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var monthlyCollectionLimit: Int { Limit.monthlyCollectionChanges }

    func currentMonthlyCollectionUsage(date: Date = Date()) -> Int {
        lock.lock()
        defer { lock.unlock() }
        resetCollectionMonthIfNeeded(date: date)
        return defaults.integer(forKey: Key.collectionCount)
    }

    func validateCollectionChange(date: Date = Date()) throws {
        lock.lock()
        defer { lock.unlock() }
        resetCollectionMonthIfNeeded(date: date)

        guard defaults.integer(forKey: Key.collectionCount) < Limit.monthlyCollectionChanges else {
            throw CollectionUsageLimitError.monthlyCollectionLimitReached
        }
    }

    func recordCollectionChange(date: Date = Date()) {
        lock.lock()
        defer { lock.unlock() }
        resetCollectionMonthIfNeeded(date: date)
        defaults.set(defaults.integer(forKey: Key.collectionCount) + 1, forKey: Key.collectionCount)
    }

    func validateLikeAddition(currentTotalLikes: Int, date: Date = Date()) throws {
        lock.lock()
        defer { lock.unlock() }
        resetLikeDayIfNeeded(date: date)

        guard currentTotalLikes < Limit.totalLikes else {
            throw CollectionUsageLimitError.totalLikeLimitReached
        }

        guard defaults.integer(forKey: Key.likeCount) < Limit.dailyLikes else {
            throw CollectionUsageLimitError.dailyLikeLimitReached
        }
    }

    func recordLikeAddition(date: Date = Date()) {
        lock.lock()
        defer { lock.unlock() }
        resetLikeDayIfNeeded(date: date)
        defaults.set(defaults.integer(forKey: Key.likeCount) + 1, forKey: Key.likeCount)
    }
}

private extension CollectionUsageLimiter {
    func resetCollectionMonthIfNeeded(date: Date) {
        let key = monthKey(for: date)
        guard defaults.string(forKey: Key.collectionMonth) != key else { return }
        defaults.set(key, forKey: Key.collectionMonth)
        defaults.set(0, forKey: Key.collectionCount)
    }

    func resetLikeDayIfNeeded(date: Date) {
        let key = dayKey(for: date)
        guard defaults.string(forKey: Key.likeDay) != key else { return }
        defaults.set(key, forKey: Key.likeDay)
        defaults.set(0, forKey: Key.likeCount)
    }

    func monthKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }

    func dayKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}
