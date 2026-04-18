//
//  LocalizationMapper.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//

    // LocalizationMapper.swift
    // Fragella API 영어 원문 → 킁킁 한국어 변환 전담 파일

import Foundation

enum LocalizationMapper {

        // MARK: - Accord (향 계열)
        // Fragella Main Accords 값은 복합형 문자열로 오는 경우가 많아 contains 기반 매핑
    static func accord(_ value: String) -> String {
        let s = value.lowercased().trimmingCharacters(in: .whitespaces)
        switch true {
            case s.contains("floral"):              return "꽃향기"
            case s.contains("woody"),
                s.contains("wood"),
                s.contains("cedar"),
                s.contains("sandalwood"):          return "나무·흙내음"
            case s.contains("amber"),
                s.contains("oriental"),
                s.contains("vanilla"),
                s.contains("warm"):               return "달콤한 따뜻함"
            case s.contains("fresh"),
                s.contains("citrus"),
                s.contains("bergamot"),
                s.contains("lemon"):              return "상쾌한 향"
            case s.contains("aqua"),
                s.contains("water"),
                s.contains("marine"),
                s.contains("ozonic"):             return "물·바다 느낌"
            case s.contains("musk"),
                s.contains("powdery"),
                s.contains("soft"):              return "포근한 향"
            case s.contains("fruit"),
                s.contains("gourmand"),
                s.contains("sweet"),
                s.contains("tropical"):          return "과일향"
            case s.contains("aroma"),
                s.contains("spic"),
                s.contains("herb"),
                s.contains("green"),
                s.contains("earthy"):            return "허브·스파이시"
            default:                              return value // 매핑 안 되면 원문 유지 (디버깅용)
        }
    }

        // MARK: - Gender (성별)
    static func gender(_ value: String) -> String {
        switch value.lowercased() {
            case "women", "female":  return "여성향"
            case "men", "male":      return "남성향"
            case "unisex":           return "유니섹스"
            default:                 return value
        }
    }

        // MARK: - Concentration (농도)
    static func concentration(_ value: String) -> String {
        switch value.lowercased() {
            case "parfum", "extrait de parfum":  return "퍼퓸"
            case "eau de parfum":               return "오 드 퍼퓸"
            case "eau de toilette":             return "오 드 뚜왈렛"
            case "eau de cologne":              return "오 드 코롱"
            case "eau fraiche":                 return "오 프레쉬"
            default:                            return value
        }
    }

        // MARK: - Longevity (지속력)
    static func longevity(_ value: String) -> String {
        switch value.lowercased() {
            case "very long lasting": return "매우 오래 지속"
            case "long lasting":      return "오래 지속"
            case "moderate":          return "보통"
            case "weak":              return "약함"
            case "poor":              return "매우 약함"
            default:                  return value
        }
    }

        // MARK: - Sillage (확산력)
    static func sillage(_ value: String) -> String {
        switch value.lowercased() {
            case "enormous":  return "매우 강함"
            case "strong":    return "강함"
            case "moderate":  return "보통"
            case "intimate":  return "은은함"
            case "soft":      return "부드러움"
            default:          return value
        }
    }

        // MARK: - Season (계절)
    static func season(_ value: String) -> String {
        switch value.lowercased() {
            case "spring": return "봄"
            case "summer": return "여름"
            case "fall", "autumn": return "가을"
            case "winter": return "겨울"
            default:       return value
        }
    }

        // MARK: - Price Value (가격 대비 가치)
    static func priceValue(_ value: String) -> String {
        switch value.lowercased() {
            case "great value":   return "가성비 좋음"
            case "good value":    return "무난함"
            case "ok":            return "보통"
            case "overpriced":    return "가격 대비 아쉬움"
            case "way overpriced": return "많이 비쌈"
            default:              return value
        }
    }

        // MARK: - Popularity (인기도)
    static func popularity(_ value: String) -> String {
        switch value.lowercased() {
            case "very high": return "매우 인기"
            case "high":      return "인기"
            case "moderate":  return "보통"
            case "low":       return "낮음"
            default:          return value
        }
    }
}
