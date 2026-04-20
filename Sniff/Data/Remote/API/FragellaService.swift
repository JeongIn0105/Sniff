//
//  FragellaService.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import RxSwift

// MARK: - AccordStrength

enum AccordStrength: String {
    case dominant
    case prominent
    case moderate
    case subtle

    init?(rawDescription: String) {
        switch rawDescription.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "dominant":  self = .dominant
        case "prominent": self = .prominent
        case "moderate":  self = .moderate
        case "subtle":    self = .subtle
        default:          return nil
        }
    }

    var weight: Double {
        switch self {
        case .dominant:  return 1.0
        case .prominent: return 0.8
        case .moderate:  return 0.55
        case .subtle:    return 0.3
        }
    }
}

// MARK: - FragellaPerfume

struct FragellaPerfume {
    let id: String
    let name: String
    let brand: String
    let imageUrl: String?
    let mainAccords: [String]
    let mainAccordStrengths: [String: AccordStrength]
    let topNotes: [String]?
    let middleNotes: [String]?
    let baseNotes: [String]?
    let concentration: String?
    let gender: String?
    let season: [String]?
    let situation: [String]?
    let longevity: String?
    let sillage: String?

    init(
        id: String,
        name: String,
        brand: String,
        imageUrl: String?,
        mainAccords: [String],
        mainAccordStrengths: [String: AccordStrength] = [:],
        topNotes: [String]?,
        middleNotes: [String]?,
        baseNotes: [String]?,
        concentration: String?,
        gender: String?,
        season: [String]?,
        situation: [String]?,
        longevity: String?,
        sillage: String?
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.imageUrl = Self.normalizeImageURL(imageUrl)

        let canonicalMainAccords = ScentFamilyNormalizer.canonicalNames(for: mainAccords)
        self.mainAccords = canonicalMainAccords
        self.mainAccordStrengths = Self.normalizeAccordStrengths(
            from: mainAccordStrengths,
            orderedMainAccords: canonicalMainAccords
        )
        self.topNotes = topNotes
        self.middleNotes = middleNotes
        self.baseNotes = baseNotes
        self.concentration = concentration
        self.gender = gender
        self.season = season
        self.situation = situation
        self.longevity = longevity
        self.sillage = sillage
    }

    // MARK: - 이미지 URL 정규화 (http → https 변환 등)
    private static func normalizeImageURL(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("//") {
            return "https:\(trimmed)"
        } else if trimmed.hasPrefix("http://") {
            return "https://" + trimmed.dropFirst("http://".count)
        } else {
            return trimmed
        }
    }

    // MARK: - Accord Strength 정규화 (rawStrengths에 없는 accord는 순서 기반 fallback 적용)
    private static func normalizeAccordStrengths(
        from rawStrengths: [String: AccordStrength],
        orderedMainAccords: [String]
    ) -> [String: AccordStrength] {
        var normalized: [String: AccordStrength] = [:]
        for (rawAccord, strength) in rawStrengths {
            guard let canonical = ScentFamilyNormalizer.canonicalName(for: rawAccord) else { continue }
            let existing = normalized[canonical]?.weight ?? -1
            if strength.weight > existing {
                normalized[canonical] = strength
            }
        }
        let fallbackStrengths: [AccordStrength] = [.dominant, .prominent, .moderate, .subtle]
        for (index, accord) in orderedMainAccords.enumerated() {
            guard normalized[accord] == nil else { continue }
            normalized[accord] = index < fallbackStrengths.count ? fallbackStrengths[index] : .subtle
        }
        return normalized
    }
}

// MARK: - FragellaService

final class FragellaService {

    static let shared = FragellaService()

    private let baseURL = "https://api.fragella.com/api/v1"

    // MARK: - 향수 검색 (RxSwift Single 반환)
    func search(query: String, limit: Int = 20) -> Single<[FragellaPerfume]> {
        Single.create { [weak self] observer in
            guard let self else {
                observer(.success([]))
                return Disposables.create()
            }
            Task {
                do {
                    let results = try await self.requestSearch(query: query, limit: limit)
                    observer(.success(results))
                } catch {
                    observer(.failure(error))
                }
            }
            return Disposables.create()
        }
    }

    // MARK: - 향수 상세 조회 (RxSwift Single 반환)
    func fetchDetail(perfumeId: String) -> Single<FragellaPerfume> {
        Single.create { [weak self] observer in
            guard let self else {
                observer(.failure(FragellaError.invalidURL))
                return Disposables.create()
            }
            Task {
                do {
                    let result = try await self.requestDetail(perfumeId: perfumeId)
                    observer(.success(result))
                } catch {
                    observer(.failure(error))
                }
            }
            return Disposables.create()
        }
    }

    // MARK: - 추천용 향수 계열별 조회 (RxSwift Single 반환)
    func fetchByFamilies(families: [String], limit: Int = 20) -> Single<[FragellaPerfume]> {
        Single.create { [weak self] observer in
            guard let self else {
                observer(.success([]))
                return Disposables.create()
            }
            Task {
                do {
                    let results = try await self.requestByFamilies(families: families, limit: limit)
                    observer(.success(results))
                } catch {
                    observer(.failure(error))
                }
            }
            return Disposables.create()
        }
    }

    // MARK: - 네트워크 요청 (검색)
    private func requestSearch(query: String, limit: Int) async throws -> [FragellaPerfume] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(baseURL)/fragrances?search=\(encoded)&limit=\(limit)") else {
            throw FragellaError.invalidURL
        }
        var req = URLRequest(url: url)
        req.setValue(try apiKey(), forHTTPHeaderField: "x-api-key")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw FragellaError.invalidResponse }
        return try FragellaResponseParser.parsePerfumeList(from: data)
    }

    // MARK: - 네트워크 요청 (상세)
    private func requestDetail(perfumeId: String) async throws -> FragellaPerfume {
        guard !perfumeId.hasPrefix("local-") else {
            throw FragellaError.invalidDetailIdentifier
        }
        guard let url = URL(string: "\(baseURL)/fragrances/\(perfumeId)") else {
            throw FragellaError.invalidURL
        }
        var req = URLRequest(url: url)
        req.setValue(try apiKey(), forHTTPHeaderField: "x-api-key")

        print("[Fragella Detail] requestURL: \(url.absoluteString)")
        print("[Fragella Detail] perfumeId: \(perfumeId)")

        let (data, response) = try await URLSession.shared.data(for: req)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("[Fragella Detail] statusCode: \(statusCode)")
        print("[Fragella Detail] responseBody: \(Self.debugResponseSnippet(from: data))")

        guard statusCode == 200 else { throw FragellaError.invalidResponse }

        let isLikelyHTMLResponse = data.starts(with: Data("<!DOCTYPE html>".utf8))
            || data.starts(with: Data("<html".utf8))
        if isLikelyHTMLResponse {
            throw FragellaError.invalidResponse
        }

        return try FragellaResponseParser.parsePerfumeDetail(from: data)
    }

    // MARK: - 네트워크 요청 (계열별 조회)
    private func requestByFamilies(families: [String], limit: Int) async throws -> [FragellaPerfume] {
        let familyQuery = families.joined(separator: ",")
        guard let url = URL(string: "\(baseURL)/fragrances?accords=\(familyQuery)&limit=\(limit)") else {
            throw FragellaError.invalidURL
        }
        var req = URLRequest(url: url)
        req.setValue(try apiKey(), forHTTPHeaderField: "x-api-key")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw FragellaError.invalidResponse }
        return try FragellaResponseParser.parsePerfumeList(from: data)
    }

    private func apiKey() throws -> String {
        try AppSecrets.fragellaAPIKey()
    }

    private static func debugResponseSnippet(from data: Data, limit: Int = 300) -> String {
        let text = String(data: data, encoding: .utf8) ?? "<non-utf8 response: \(data.count) bytes>"
        if text.count <= limit {
            return text
        }
        let endIndex = text.index(text.startIndex, offsetBy: limit)
        return String(text[..<endIndex])
    }
}

// MARK: - FragellaResponseParser

private enum FragellaResponseParser {

    static func parsePerfumeList(from data: Data) throws -> [FragellaPerfume] {
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        if let array = jsonObject as? [[String: Any]] {
            return array.compactMap(parsePerfume(dictionary:))
        }
        guard let dictionary = jsonObject as? [String: Any] else {
            throw FragellaError.decodingFailed
        }
        for key in ["data", "results", "items", "fragrances", "perfumes"] {
            if let array = dictionary[key] as? [[String: Any]] {
                return array.compactMap(parsePerfume(dictionary:))
            }
        }
        if let perfume = parsePerfume(dictionary: dictionary) {
            return [perfume]
        }
        throw FragellaError.decodingFailed
    }

    static func parsePerfumeDetail(from data: Data) throws -> FragellaPerfume {
        guard let perfume = try parsePerfumeList(from: data).first else {
            throw FragellaError.decodingFailed
        }
        return perfume
    }

    private static func parsePerfume(dictionary: [String: Any]) -> FragellaPerfume? {
        guard
            let name  = stringValue(forKeys: ["name", "Name", "perfume_name", "fragrance_name"], in: dictionary),
            let brand = stringValue(forKeys: ["brand", "Brand", "brand_name", "house"], in: dictionary)
        else { return nil }
        let id = detailIdentifier(in: dictionary) ?? makeSyntheticID(name: name, brand: brand)
        return FragellaPerfume(
            id: id,
            name: name,
            brand: brand,
            imageUrl: stringValue(
                forKeys: ["image_url", "Image URL", "image", "imageURL", "thumbnail_url", "thumbnail", "photo_url"],
                in: dictionary
            ),
            mainAccords: mainAccords(in: dictionary),
            mainAccordStrengths: mainAccordStrengths(in: dictionary),
            topNotes: noteNames(in: dictionary, keys: ["Top", "top"])
                ?? stringArrayValue(forKeys: ["top_notes", "topNotes"], in: dictionary),
            middleNotes: noteNames(in: dictionary, keys: ["Middle", "Heart", "middle", "heart"])
                ?? stringArrayValue(forKeys: ["middle_notes", "middleNotes", "heart_notes"], in: dictionary),
            baseNotes: noteNames(in: dictionary, keys: ["Base", "base"])
                ?? stringArrayValue(forKeys: ["base_notes", "baseNotes", "base"], in: dictionary),
            concentration: stringValue(forKeys: ["concentration", "OilType"], in: dictionary),
            gender: stringValue(forKeys: ["gender", "Gender", "target_gender"], in: dictionary),
            season: seasonRankingNames(in: dictionary)
                ?? stringArrayValue(forKeys: ["season", "seasons"], in: dictionary),
            situation: stringArrayValue(forKeys: ["situation", "situations", "occasion", "occasions"], in: dictionary),
            longevity: stringValue(forKeys: ["longevity", "Longevity"], in: dictionary),
            sillage: stringValue(forKeys: ["sillage", "Sillage"], in: dictionary)
        )
    }

    private static func mainAccords(in dictionary: [String: Any]) -> [String] {
        if let accords = stringArrayValue(forKeys: ["Main Accords", "main_accords"], in: dictionary) {
            return ScentFamilyNormalizer.canonicalNames(for: accords)
        }
        let fallback = [
            stringValue(forKeys: ["scent_family", "accord", "main_accord"], in: dictionary),
            stringValue(forKeys: ["scent_family2", "secondary_accord", "sub_accord"], in: dictionary)
        ].compactMap { $0 }
        return ScentFamilyNormalizer.canonicalNames(for: fallback)
    }

    private static func mainAccordStrengths(in dictionary: [String: Any]) -> [String: AccordStrength] {
        guard let rawStrengths = dictionary["Main Accords Percentage"] as? [String: Any] else { return [:] }
        var result: [String: AccordStrength] = [:]
        for (rawAccord, rawStrength) in rawStrengths {
            guard
                let canonical = ScentFamilyNormalizer.canonicalName(for: rawAccord),
                let strengthString = rawStrength as? String,
                let strength = AccordStrength(rawDescription: strengthString)
            else { continue }
            let existing = result[canonical]?.weight ?? -1
            if strength.weight > existing {
                result[canonical] = strength
            }
        }
        return result
    }

    private static func noteNames(in dictionary: [String: Any], keys: [String]) -> [String]? {
        guard let notesObject = dictionary["Notes"] as? [String: Any] else { return nil }
        for key in keys {
            guard let values = notesObject[key] as? [[String: Any]] else { continue }
            let names = values
                .compactMap { ($0["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !names.isEmpty { return names }
        }
        return nil
    }

    private static func seasonRankingNames(in dictionary: [String: Any]) -> [String]? {
        guard let raw = dictionary["Season Ranking"] as? [[String: Any]] else { return nil }
        let seasons = raw
            .compactMap { ($0["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return seasons.isEmpty ? nil : seasons
    }

    private static func stringValue(forKeys keys: [String], in dictionary: [String: Any]) -> String? {
        for key in keys {
            guard let raw = dictionary[key] else { continue }
            if let s = raw as? String {
                let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { return t }
            }
            if let n = raw as? NSNumber { return n.stringValue }
        }
        return nil
    }

    private static func stringArrayValue(forKeys keys: [String], in dictionary: [String: Any]) -> [String]? {
        for key in keys {
            guard let raw = dictionary[key] else { continue }
            if let arr = raw as? [String] {
                let filtered = arr.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                if !filtered.isEmpty { return filtered }
            }
            if let arr = raw as? [Any] {
                let strings = arr.compactMap { v -> String? in
                    if let s = v as? String {
                        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                        return t.isEmpty ? nil : t
                    }
                    if let n = v as? NSNumber { return n.stringValue }
                    return nil
                }
                if !strings.isEmpty { return strings }
            }
            if let s = raw as? String {
                let parts = s.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !parts.isEmpty { return parts }
            }
        }
        return nil
    }

    private static func detailIdentifier(in dictionary: [String: Any]) -> String? {
        if let identifier = stringValue(
            forKeys: [
                "id",
                "ID",
                "_id",
                "perfume_id",
                "fragrance_id",
                "slug",
                "Slug",
                "perfume_slug",
                "fragrance_slug",
                "seo_slug",
                "url_slug",
                "uuid"
            ],
            in: dictionary
        ) {
            return identifier
        }

        for key in ["url", "detail_url", "permalink", "href", "link"] {
            guard let rawValue = stringValue(forKeys: [key], in: dictionary) else { continue }
            guard let extracted = lastPathComponent(from: rawValue) else { continue }
            return extracted
        }

        return nil
    }

    private static func lastPathComponent(from rawValue: String) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), let component = url.pathComponents.last {
            let normalized = component.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return normalized.isEmpty ? nil : normalized
        }

        let component = trimmed.split(separator: "/").last.map(String.init)
        guard let component else { return nil }
        let normalized = component.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return normalized.isEmpty ? nil : normalized
    }

    private static func makeSyntheticID(name: String, brand: String) -> String {
        "local-" + "\(brand)-\(name)"
            .lowercased()
            .map { $0.isLetter || $0.isNumber ? $0 : "-" }
            .map(String.init)
            .joined()
    }
}

// MARK: - Error

enum FragellaError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed
    case invalidDetailIdentifier

    var errorDescription: String? {
        switch self {
        case .invalidURL:       return "잘못된 URL이에요"
        case .invalidResponse:  return "서버 응답이 올바르지 않아요"
        case .decodingFailed:   return "데이터를 불러오는 데 실패했어요"
        case .invalidDetailIdentifier: return "상세 조회에 사용할 수 없는 향수 식별자예요"
        }
    }
}
