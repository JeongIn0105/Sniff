//
//  TastingNoteModel.swift
//  Sniff
//
//  Created by 이정인 on 4/16/26.
//

// MARK: - 데이터 모델
import Foundation
import FirebaseFirestore
import SwiftUI

// MARK: - 시향 기록 모델

struct TastingNote: Identifiable, Codable {
    @DocumentID var id: String?
    var perfumeName: String
    var brandName: String
    var mainAccords: [String]
    var concentration: String?
    var rating: Int
    var longevity: Int           // 하위 호환성을 위해 유지 (UI에서는 미사용)
    var moodTags: [String]
    var revisitDesire: String?   // 다시 쓰고 싶은지 태그 (선택)
    var memo: String
    var perfumeImageURL: String?
    var fragranceID: String?
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - 다시 쓰고 싶은지 태그 목록 (4개, 단일 선택)

let kRevisitDesireList: [String] = [
    "매일 뿌리고 싶어",
    "가끔 꺼내고 싶어",
    "기억에 남아, 근데 내 향은 아니야",
    "다시 맡고 싶지 않아"
]

// MARK: - Fragella 향수 검색 결과 모델

struct FragellaFragrance: Identifiable {
    let id: String
    let name: String            // 영문명 (원본)
    let brand: String           // 영문 브랜드명 (원본)
    let koreanName: String?     // 한국어 향수명
    let koreanBrand: String?    // 한국어 브랜드명
    let mainAccords: [String]   // 한국어로 변환된 향 계열
    let concentration: String?
    let imageURL: String?

    /// 화면 표시용 향수명 — 한국어 있으면 한국어 우선
    var displayName: String { koreanName ?? name }

    /// 화면 표시용 브랜드명 — 한국어 있으면 한국어 우선, 없으면 번역 시도
    var displayBrand: String {
        if let k = koreanBrand { return k }
        return PerfumeKoreanTranslator.koreanBrand(for: brand)
    }
}

// MARK: - 분위기&이미지 태그 목록 (18개)

let kMoodTagList: [String] = [
    "따뜻한", "시원한", "은은한", "강렬한",
    "상큼한", "달콤한", "보송보송한", "묵직한",
    "가벼운", "깨끗한", "포근한", "세련된",
    "고급스러운", "자연스러운", "신비로운",
    "활기찬", "중성적인", "여유로운"
]

// MARK: - 향 계열(Accord) 색상

extension String {

    var accordColor: Color {
        switch self {
        // ── 플로럴 계열 ──
        case "플로럴", "플로리엔탈":    return Color(red: 0.95, green: 0.55, blue: 0.75)
        case "화이트 플로럴":           return Color(red: 0.95, green: 0.60, blue: 0.78)
        case "로즈":                    return Color(red: 0.92, green: 0.28, blue: 0.50)
        case "재스민":                  return Color(red: 0.90, green: 0.72, blue: 0.20)
        case "이리스":                  return Color(red: 0.72, green: 0.55, blue: 0.88)
        case "튜베로즈":                return Color(red: 0.92, green: 0.65, blue: 0.78)
        // ── 시트러스/프레시 계열 ──
        case "시트러스":                return Color(red: 1.00, green: 0.75, blue: 0.08)
        case "프레시", "아로마틱":      return Color(red: 0.18, green: 0.72, blue: 0.62)
        case "아쿠아틱", "오존":        return Color(red: 0.18, green: 0.52, blue: 0.88)
        case "시원한":                  return Color(red: 0.25, green: 0.62, blue: 0.92)
        case "헤르바시어스", "그린":    return Color(red: 0.28, green: 0.72, blue: 0.32)
        // ── 우디/머스키/앰버 계열 ──
        case "우디", "우드":            return Color(red: 0.58, green: 0.38, blue: 0.18)
        case "레더":                    return Color(red: 0.42, green: 0.26, blue: 0.16)
        case "스모키":                  return Color(red: 0.35, green: 0.35, blue: 0.38)
        case "어니멀릭":                return Color(red: 0.52, green: 0.32, blue: 0.22)
        case "머스키":                  return Color(red: 0.55, green: 0.42, blue: 0.72)
        // ── 앰버/오리엔탈 계열 ──
        case "앰버", "앰버(오리엔탈)":  return Color(red: 0.85, green: 0.60, blue: 0.10)
        case "바닐라":                  return Color(red: 0.92, green: 0.72, blue: 0.35)
        case "발사믹":                  return Color(red: 0.72, green: 0.42, blue: 0.12)
        case "구르망":                  return Color(red: 0.88, green: 0.52, blue: 0.22)
        // ── 스파이시/웜 계열 ──
        case "스파이시":                return Color(red: 0.85, green: 0.22, blue: 0.18)
        case "따뜻한":                  return Color(red: 1.00, green: 0.55, blue: 0.20)
        // ── 스위트/파우더리/프루티 계열 ──
        case "스위트":                  return Color(red: 0.95, green: 0.58, blue: 0.72)
        case "프루티":                  return Color(red: 0.95, green: 0.35, blue: 0.42)
        case "파우더리":                return Color(red: 0.78, green: 0.58, blue: 0.88)
        default:                        return Color(.systemGray2)
        }
    }
    var accordBackgroundColor: Color { accordColor.opacity(0.12) }
    var accordBorderColor: Color { accordColor.opacity(0.45) }
}

// MARK: - 영문 태그 → 한국어 태그 매핑 (이전 데이터 호환용)

let kLegacyTagToKorean: [String: String] = [
    "Woody": "우디", "Fresh": "프레시", "Amber(Oriental)": "앰버(오리엔탈)",
    "Musky": "머스키", "White Floral": "화이트 플로럴", "Rose": "로즈",
    "Powdery": "파우더리", "Vanilla": "바닐라", "Spicy": "스파이시",
    "Citrus": "시트러스", "Green": "그린", "Aquatic": "아쿠아틱",
    "Leather": "레더", "Oud": "우드",
    // 구 태그 → 신 태그 마이그레이션
    "우디": "묵직한", "앰버(오리엔탈)": "따뜻한", "바닐라": "달콤한",
    "시트러스": "상큼한", "그린": "자연스러운", "아쿠아틱": "시원한",
]

// MARK: - 별점 라벨

extension Int {
    var ratingLabel: String {
        switch self {
        case 1: return "나와 맞지 않는 향이에요"
        case 2: return "조금 아쉬운 편이에요"
        case 3: return "보통이에요"
        case 4: return "나와 잘 맞는 향이에요"
        case 5: return "나와 매우 잘 맞는 향이에요"
        default: return ""
        }
    }
}

// MARK: - 날짜 포맷

extension Date {
    var tastingNoteFormat: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy. MM. dd"
        return f.string(from: self)
    }
}
