//
//  NoteToFamilyMapper.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//

    //
    //  NoteToFamilyMapper.swift
    //  Sniff
    //
    //  노트 유사도 시스템의 핵심.
    //
    //  Accord가 "이 향수는 Floral이다"라는 장르 정보라면,
    //  노트는 "그 Floral이 구체적으로 Rose인지 Jasmine인지 Lily인지"를 말해준다.
    //
    //  같은 Floral이라도:
    //    Rose     → 풍성하고 클래식한 Floral
    //    Jasmine  → 관능적이고 무거운 Floral → Soft Floral로 흐름
    //    Lily     → 청량하고 가벼운 Floral → Fresh 쪽으로 흐름
    //
    //  이 세분화가 벡터 추천의 정확도를 높여준다.
    //
    //  노트 위치별 가중치:
    //    Base note  × 0.7 — 향수의 진짜 정체성. 남아있는 잔향.
    //    Middle note × 0.5 — 향수의 심장. 가장 오래 머무는 계층.
    //    Top note   × 0.3 — 첫인상. 빠르게 사라지지만 강렬한 신호.
    //

import Foundation

enum NotePosition {
    case top
    case middle
    case base

    var weight: Double {
        switch self {
            case .top:    return 0.3
            case .middle: return 0.5
            case .base:   return 0.7
        }
    }
}

struct NoteFamilyMapping {
    let family: String
    let strength: Double  // 0.0~1.0, 이 노트가 해당 계열을 얼마나 대표하는지
}

enum NoteToFamilyMapper {

        // MARK: - 외부 인터페이스

        /// FragellaPerfume의 top/middle/base notes를 받아
        /// 계열별 보조 가중치 벡터를 반환
        /// 반환값은 정규화되지 않은 raw 점수 — PerfumeScorer에서 accord 벡터와 합산
    static func noteVector(
        topNotes: [String]?,
        middleNotes: [String]?,
        baseNotes: [String]?
    ) -> [String: Double] {
        var vector: [String: Double] = [:]

        func accumulate(_ notes: [String]?, position: NotePosition) {
            guard let notes else { return }
            for note in notes {
                for mapping in mappings(for: note) {
                    let score = mapping.strength * position.weight
                    vector[mapping.family, default: 0] += score
                }
            }
        }

        accumulate(topNotes,    position: .top)
        accumulate(middleNotes, position: .middle)
        accumulate(baseNotes,   position: .base)

        let canonicalized = Dictionary(grouping: vector.compactMap { key, value -> (String, Double)? in
            guard let family = ScentFamilyNormalizer.canonicalName(for: key) else { return nil }
            return (family, value)
        }, by: \.0)
        .mapValues { pairs in
            pairs.reduce(0) { $0 + $1.1 }
        }

        return normalize(canonicalized)
    }

        // MARK: - 노트 → 계열 매핑

    static func mappings(for note: String) -> [NoteFamilyMapping] {
        let key = note
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return noteMap[key]
        ?? fuzzyMatch(for: key)
        ?? []
    }

        // MARK: - 매핑 테이블
        // 값은 [NoteFamilyMapping] — 하나의 노트가 여러 계열에 걸칠 수 있음
        // 예) Vanilla → Amber 0.9 + Soft Floral 0.2 (달콤함이 약간의 파우더리함을 동반)

    private static let noteMap: [String: [NoteFamilyMapping]] = [

        // MARK: Citrus 계열
        "bergamot":        [.init(family: "Citrus",  strength: 1.0),
                            .init(family: "Fresh",   strength: 0.4)],
        "lemon":           [.init(family: "Citrus",  strength: 1.0)],
        "lime":            [.init(family: "Citrus",  strength: 1.0)],
        "grapefruit":      [.init(family: "Citrus",  strength: 0.9),
                            .init(family: "Fresh",   strength: 0.3)],
        "orange":          [.init(family: "Citrus",  strength: 0.9)],
        "mandarin orange": [.init(family: "Citrus",  strength: 0.9)],
        "mandarin":        [.init(family: "Citrus",  strength: 0.9)],
        "yuzu":            [.init(family: "Citrus",  strength: 0.9),
                            .init(family: "Fresh",   strength: 0.3)],
        "petitgrain":      [.init(family: "Citrus",  strength: 0.7),
                            .init(family: "Woody",   strength: 0.3)],
        "neroli":          [.init(family: "Citrus",  strength: 0.6),
                            .init(family: "Floral",  strength: 0.4)],

        // MARK: Fresh / Aquatic 계열
        "sea salt":        [.init(family: "Water",   strength: 1.0)],
        "ocean":           [.init(family: "Water",   strength: 1.0)],
        "marine":          [.init(family: "Water",   strength: 1.0)],
        "ozone":           [.init(family: "Water",   strength: 0.9),
                            .init(family: "Fresh",   strength: 0.3)],
        "water lily":      [.init(family: "Water",   strength: 0.8),
                            .init(family: "Floral",  strength: 0.4)],
        "green tea":       [.init(family: "Fresh",   strength: 0.7),
                            .init(family: "Aromatic",strength: 0.3)],
        "cucumber":        [.init(family: "Fresh",   strength: 0.8),
                            .init(family: "Water",   strength: 0.3)],

        // MARK: Floral 계열
        "rose":            [.init(family: "Floral",      strength: 1.0)],
        "peony":           [.init(family: "Floral",      strength: 0.9),
                            .init(family: "Soft Floral", strength: 0.2)],
        "jasmine":         [.init(family: "Floral",      strength: 0.9),
                            .init(family: "Soft Floral", strength: 0.3)],
        "ylang ylang":     [.init(family: "Floral",      strength: 0.8),
                            .init(family: "Amber",       strength: 0.2)],
        "tuberose":        [.init(family: "Floral",      strength: 0.9),
                            .init(family: "Soft Floral", strength: 0.2)],
        "magnolia":        [.init(family: "Floral",      strength: 0.8)],
        "cherry blossom":  [.init(family: "Floral",      strength: 0.8),
                            .init(family: "Soft Floral", strength: 0.3)],

        // MARK: Soft Floral / Powdery 계열
        "iris":            [.init(family: "Soft Floral", strength: 0.9),
                            .init(family: "Woody",       strength: 0.2)],
        "violet":          [.init(family: "Soft Floral", strength: 0.8),
                            .init(family: "Floral",      strength: 0.3)],
        "lily of the valley": [.init(family: "Soft Floral", strength: 0.8),
                               .init(family: "Fresh",    strength: 0.3)],
        "lily":            [.init(family: "Soft Floral", strength: 0.7),
                            .init(family: "Floral",      strength: 0.4)],
        "geranium":        [.init(family: "Soft Floral", strength: 0.7),
                            .init(family: "Floral",      strength: 0.4)],
        "heliotrope":      [.init(family: "Soft Floral", strength: 0.9),
                            .init(family: "Amber",       strength: 0.2)],
        "orris":           [.init(family: "Soft Floral", strength: 0.9)],
        "ambrette":        [.init(family: "Soft Floral", strength: 0.7),
                            .init(family: "Musk",        strength: 0.4)],

        // MARK: Fruity 계열
        "apple":           [.init(family: "Fruity",  strength: 1.0)],
        "green apple":     [.init(family: "Fruity",  strength: 0.9),
                            .init(family: "Fresh",   strength: 0.3)],
        "peach":           [.init(family: "Fruity",  strength: 1.0)],
        "pear":            [.init(family: "Fruity",  strength: 0.9),
                            .init(family: "Fresh",   strength: 0.2)],
        "raspberry":       [.init(family: "Fruity",  strength: 0.9)],
        "black currant":   [.init(family: "Fruity",  strength: 0.8),
                            .init(family: "Fresh",   strength: 0.3)],
        "fig":             [.init(family: "Fruity",  strength: 0.8),
                            .init(family: "Green",   strength: 0.3)],
        "quince":          [.init(family: "Fruity",  strength: 0.9)],
        "plum":            [.init(family: "Fruity",  strength: 0.8),
                            .init(family: "Amber",   strength: 0.2)],

        // MARK: Green / Aromatic 계열
        "lavender":        [.init(family: "Aromatic", strength: 1.0),
                            .init(family: "Fresh",    strength: 0.3)],
        "sage":            [.init(family: "Aromatic", strength: 0.9)],
        "rosemary":        [.init(family: "Aromatic", strength: 0.9)],
        "thyme":           [.init(family: "Aromatic", strength: 0.8)],
        "basil":           [.init(family: "Aromatic", strength: 0.8),
                            .init(family: "Green",    strength: 0.3)],
        "mint":            [.init(family: "Aromatic", strength: 0.7),
                            .init(family: "Fresh",    strength: 0.5)],
        "galbanum":        [.init(family: "Green",    strength: 0.9)],
        "violet leaf":     [.init(family: "Green",    strength: 0.8),
                            .init(family: "Fresh",    strength: 0.3)],
        "grass":           [.init(family: "Green",    strength: 0.9)],
        "bamboo":          [.init(family: "Green",    strength: 0.7),
                            .init(family: "Fresh",    strength: 0.4)],

        // MARK: Woody 계열
        "sandalwood":      [.init(family: "Woody",   strength: 1.0),
                            .init(family: "Amber",   strength: 0.2)],
        "cedar":           [.init(family: "Woody",   strength: 1.0)],
        "cedarwood":       [.init(family: "Woody",   strength: 1.0)],
        "vetiver":         [.init(family: "Woody",   strength: 0.8),
                            .init(family: "Dry Woods", strength: 0.4)],
        "oud":             [.init(family: "Woody",   strength: 0.9),
                            .init(family: "Dry Woods", strength: 0.5)],
        "agarwood":        [.init(family: "Woody",   strength: 0.9),
                            .init(family: "Dry Woods", strength: 0.5)],
        "guaiac wood":     [.init(family: "Woody",   strength: 0.8),
                            .init(family: "Dry Woods", strength: 0.3)],
        "birch":           [.init(family: "Dry Woods", strength: 0.8),
                            .init(family: "Woody",   strength: 0.4)],

        // MARK: Amber / Warm 계열
        "vanilla":         [.init(family: "Amber",       strength: 0.9),
                            .init(family: "Soft Floral", strength: 0.2)],
        "tonka bean":      [.init(family: "Amber",       strength: 0.9),
                            .init(family: "Woody Amber", strength: 0.2)],
        "benzyl benzoate": [.init(family: "Amber",       strength: 0.8)],
        "labdanum":        [.init(family: "Amber",       strength: 0.8),
                            .init(family: "Mossy Woods", strength: 0.3)],
        "amber":           [.init(family: "Amber",       strength: 1.0)],
        "caramel":         [.init(family: "Amber",       strength: 0.8)],
        "benzoin":         [.init(family: "Amber",       strength: 0.8),
                            .init(family: "Soft Floral", strength: 0.2)],
        "coumarin":        [.init(family: "Amber",       strength: 0.7),
                            .init(family: "Aromatic",    strength: 0.4)],

        // MARK: Spicy 계열
        "pink pepper":     [.init(family: "Aromatic", strength: 0.6),
                            .init(family: "Fresh",    strength: 0.4)],
        "black pepper":    [.init(family: "Aromatic", strength: 0.7),
                            .init(family: "Dry Woods", strength: 0.3)],
        "cardamom":        [.init(family: "Aromatic", strength: 0.8),
                            .init(family: "Amber",    strength: 0.3)],
        "cinnamon":        [.init(family: "Amber",    strength: 0.7),
                            .init(family: "Aromatic", strength: 0.4)],
        "clove":           [.init(family: "Amber",    strength: 0.6),
                            .init(family: "Aromatic", strength: 0.5)],
        "nutmeg":          [.init(family: "Aromatic", strength: 0.7),
                            .init(family: "Woody",    strength: 0.3)],
        "saffron":         [.init(family: "Amber",    strength: 0.7),
                            .init(family: "Aromatic", strength: 0.3)],

        // MARK: Musk 계열
        "musk":            [.init(family: "Musk",     strength: 1.0)],
        "white musk":      [.init(family: "Musk",     strength: 1.0),
                            .init(family: "Soft Floral", strength: 0.2)],
        "cashmeran":       [.init(family: "Musk",     strength: 0.7),
                            .init(family: "Woody Amber", strength: 0.4)],

        // MARK: Mossy / Earthy 계열
        "patchouli":       [.init(family: "Mossy Woods", strength: 1.0),
                            .init(family: "Woody",       strength: 0.3)],
        "oakmoss":         [.init(family: "Mossy Woods", strength: 1.0)],
        "moss":            [.init(family: "Mossy Woods", strength: 0.9)],
        "earth":           [.init(family: "Mossy Woods", strength: 0.8)],
        "mushroom":        [.init(family: "Mossy Woods", strength: 0.7)],

        // MARK: Dry / Leather 계열
        "leather":         [.init(family: "Dry Woods", strength: 1.0)],
        "smoke":           [.init(family: "Dry Woods", strength: 0.8)],
        "tobacco":         [.init(family: "Dry Woods", strength: 0.8),
                            .init(family: "Amber",     strength: 0.3)],
        "incense":         [.init(family: "Dry Woods", strength: 0.7),
                            .init(family: "Amber",     strength: 0.4)],
        "frankincense":    [.init(family: "Dry Woods", strength: 0.6),
                            .init(family: "Amber",     strength: 0.5)],
        "myrrh":           [.init(family: "Dry Woods", strength: 0.5),
                            .init(family: "Amber",     strength: 0.6)],
    ]

        // MARK: - 퍼지 매칭 — 완전 일치하지 않을 때 부분 문자열로 탐색

    private static func fuzzyMatch(for key: String) -> [NoteFamilyMapping]? {
        for (noteKey, mappings) in noteMap {
            if key.contains(noteKey) || noteKey.contains(key) {
                return mappings
            }
        }
        return nil
    }

        // MARK: - 정규화

    private static func normalize(_ vector: [String: Double]) -> [String: Double] {
        let total = vector.values.reduce(0, +)
        guard total > 0 else { return [:] }
        return vector.mapValues { $0 / total }
    }
}
