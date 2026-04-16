//
//  PerfumeKoreanTranslator.swift
//  Sniff
//
//  Created by 이정인 on 2026.04.16.
//

import Foundation

// MARK: - 향수 용어 한국어 변환 유틸리티

enum PerfumeKoreanTranslator {

    // MARK: - Accord(향 계열) → 한국어 변환 사전

    static let accordToKorean: [String: String] = [
        // 플로럴 계열
        "Floral": "플로럴",
        "White Floral": "화이트 플로럴",
        "Soft Floral": "소프트 플로럴",
        "Floral Woody Musk": "플로럴 우디 머스크",
        "Floral Amber": "플로럴 앰버",
        "Fresh Floral": "프레시 플로럴",
        "Rose": "로즈",
        "Jasmine": "재스민",
        "Iris": "아이리스",
        "Tuberose": "튜베로즈",
        "Violet": "바이올렛",
        "Lily": "릴리",
        "Lily of the Valley": "은방울꽃",
        "Gardenia": "가디니아",
        "Magnolia": "마그놀리아",
        "Peony": "피오니",
        "Ylang-Ylang": "일랑일랑",
        "Neroli": "네롤리",

        // 우디 계열
        "Woody": "우디",
        "Woody Amber": "우디 앰버",
        "Woody Spicy": "우디 스파이시",
        "Fresh Woody": "프레시 우디",
        "Dry Woods": "드라이 우즈",
        "Mossy Woods": "모씨 우즈",
        "Sandalwood": "샌달우드",
        "Cedarwood": "시더우드",
        "Cedar": "시더",
        "Vetiver": "베티버",
        "Patchouli": "파출리",
        "Oud": "우드",

        // 프레시 계열
        "Fresh": "프레시",
        "Fresh Spicy": "프레시 스파이시",
        "Citrus": "시트러스",
        "Aquatic": "아쿠아틱",
        "Marine": "마린",
        "Green": "그린",
        "Aromatic": "아로마틱",
        "Fougere": "푸제르",
        "Bergamot": "베르가못",
        "Lavender": "라벤더",
        "Mint": "민트",
        "Lemon": "레몬",
        "Orange": "오렌지",
        "Grapefruit": "그레이프프루트",
        "Sea": "씨",

        // 오리엔탈/앰버 계열
        "Amber": "앰버",
        "Amber(Oriental)": "앰버(오리엔탈)",
        "Amber Vanilla": "앰버 바닐라",
        "Oriental": "오리엔탈",
        "Soft Oriental": "소프트 오리엔탈",
        "Warm Spicy": "따뜻한 스파이시",
        "Spicy": "스파이시",
        "Vanilla": "바닐라",
        "Sweet": "스위트",
        "Powdery": "파우더리",
        "Musky": "머스키",
        "Musk": "머스크",
        "Incense": "인센스",
        "Resin": "레진",
        "Tobacco": "타바코",
        "Leather": "레더",
        "Saffron": "사프란",
        "Cardamom": "카다몸",
        "Cinnamon": "시나몬",
        "Pepper": "페퍼",

        // 구르망/프루티 계열
        "Fruity": "프루티",
        "Gourmand": "구르망",
        "Peach": "피치",
        "Berry": "베리",
        "Apple": "애플",
        "Pear": "페어",
        "Mango": "망고",
        "Coconut": "코코넛",
        "Honey": "허니",
        "Chocolate": "초콜릿",
        "Coffee": "커피",
        "Caramel": "카라멜",
        "Almond": "아몬드",
        "Beeswax": "비즈왁스",

        // 기타
        "Herbal": "허벌",
        "Earthy": "어시",
        "Mossy": "모씨",
        "Smoky": "스모키",
        "Chypre": "시프레",
        "Clean": "클린",
        "Soapy": "소피",
    ]

    // MARK: - 소문자 accord → 한국어 역맵 (API 소문자 대응)
    // accordToKorean 키를 전부 소문자로 낮춰서 저장 → 대소문자 무관 검색
    // uniquingKeysWith: 중복 시 마지막 값으로 덮어씀

    static let lowerAccordToKorean: [String: String] = {
        Dictionary(accordToKorean.map { ($0.key.lowercased(), $0.value) },
                   uniquingKeysWith: { _, last in last })
    }()

    // MARK: - 한국어 → Accord 역변환 (검색용)
    // uniquingKeysWith: 중복 값이 있어도 크래시 없이 마지막 값으로 덮어씀

    static let koreanToAccord: [String: String] = {
        Dictionary(accordToKorean.map { ($1, $0) }, uniquingKeysWith: { _, last in last })
    }()

    // MARK: - 브랜드명 한국어 변환 사전

    static let brandToKorean: [String: String] = [
        "Le Labo": "르 라보",
        "Chanel": "샤넬",
        "Dior": "디올",
        "Hermès": "에르메스",
        "Hermes": "에르메스",
        "Tom Ford": "톰 포드",
        "Byredo": "바이레도",
        "Jo Malone": "조 말론",
        "Jo Malone London": "조 말론 런던",
        "Acqua di Parma": "아쿠아 디 파르마",
        "Maison Margiela": "메종 마르지엘라",
        "Diptyque": "딥티크",
        "Guerlain": "겔랑",
        "Lancôme": "랑콤",
        "Cartier": "까르띠에",
        "Bulgari": "불가리",
        "Bvlgari": "불가리",
        "Giorgio Armani": "조르지오 아르마니",
        "Armani": "아르마니",
        "Yves Saint Laurent": "입생로랑",
        "Valentino": "발렌티노",
        "Versace": "베르사체",
        "Givenchy": "지방시",
        "Narciso Rodriguez": "나르시소 로드리게스",
        "Viktor & Rolf": "빅터 앤 롤프",
        "Comme des Garcons": "꼼 데 가르송",
        "Comme des Garçons": "꼼 데 가르송",
        "Maison Francis Kurkdjian": "메종 프란시스 커크쟌",
        "Frederic Malle": "프레데릭 말",
        "Frédéric Malle": "프레데릭 말",
        "Serge Lutens": "세르쥬 루탕",
        "Annick Goutal": "아닉 구탈",
        "Creed": "크리드",
        "Amouage": "아무아쥬",
        "Kilian": "킬리안",
        "By Kilian": "바이 킬리안",
        "Mancera": "만세라",
        "Nishane": "니샤네",
        "Initio": "이니시오",
        "Xerjoff": "제르조프",
        "Penhaligon's": "펜할리곤",
        "Miller Harris": "밀러 해리스",
        "Les Parfums De Rosine": "레 파르팡 드 로진",
        "Rosendo Mateu": "로센도 마테우",
        "Maison Crivelli": "메종 크리벨리",
        "Juliette Has a Gun": "줄리엣 해즈 어 건",
        "Memo Paris": "메모 파리",
        "Orto Parisi": "오르토 파리시",
        "Masque Milano": "마스크 밀라노",
        "L'Artisan Parfumeur": "라르티장 파르퍼뫄",
        "Atelier Cologne": "아뜰리에 코롱",
        "Etat Libre d'Orange": "에따 리브르 도랑쥬",
        "Parfums de Nicolai": "파르팡 드 니콜라이",
        "L'Occitane": "록시탄",
        "Issey Miyake": "이세이 미야케",
        "Thierry Mugler": "티에리 뮈글러",
        "Carolina Herrera": "캐롤리나 에레라",
        "Marc Jacobs": "마크 제이콥스",
        "Dolce & Gabbana": "돌체 앤 가바나",
        "Burberry": "버버리",
        "Hugo Boss": "휴고 보스",
        "Calvin Klein": "캘빈 클라인",
        "Ralph Lauren": "랄프 로렌",
        "Prada": "프라다",
        "Gucci": "구찌",
        "Bottega Veneta": "보테가 베네타",
        "Ferragamo": "페라가모",
        "Trussardi": "트루사르디",
        "Missoni": "미쏘니",
        "Etro": "에트로",
        "Nuxe": "뉙스",
    ]

    // MARK: - 한국어 → 브랜드 역변환
    // uniquingKeysWith: "에르메스"→Hermès/Hermes 등 중복 매핑을 안전하게 처리

    static let koreanToBrand: [String: String] = {
        Dictionary(brandToKorean.map { ($1, $0) }, uniquingKeysWith: { _, last in last })
    }()

    // MARK: - 한국어 포함 여부 확인

    static func containsKorean(_ text: String) -> Bool {
        text.unicodeScalars.contains {
            (0xAC00...0xD7A3).contains($0.value) ||  // 한글 음절
            (0x1100...0x11FF).contains($0.value) ||  // 한글 자모
            (0x3130...0x318F).contains($0.value)      // 한글 호환 자모
        }
    }

    // MARK: - Accord 한국어 변환 (단일)
    // 1) 이미 한국어  →  그대로
    // 2) 사전에 정확히 있으면  →  바로 반환
    // 3) 소문자 변환 후 lowerAccordToKorean 에서 검색  →  API 소문자 대응
    // 4) 모두 실패 시 원본 반환

    static func korean(for accord: String) -> String {
        if containsKorean(accord) { return accord }
        if let k = accordToKorean[accord] { return k }
        return lowerAccordToKorean[accord.lowercased()] ?? accord
    }

    // MARK: - Accord 배열 한국어 변환

    static func koreanAccords(for accords: [String]) -> [String] {
        accords.map { korean(for: $0) }
    }

    // MARK: - 한국어 검색어 → 영문 변환 (검색 fallback 용)
    // 완전히 일치하는 한국어 accord/brand 이름이면 영문으로 변환

    static func toEnglishQuery(_ query: String) -> String? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // accord 역변환
        if let english = koreanToAccord[trimmed] { return english }

        // 브랜드 역변환
        if let english = koreanToBrand[trimmed] { return english }

        // 부분 매칭: 브랜드명 포함된 경우
        for (korean, english) in koreanToBrand {
            if trimmed.localizedCaseInsensitiveContains(korean) {
                return trimmed.replacingOccurrences(
                    of: korean,
                    with: english,
                    options: .caseInsensitive
                )
            }
        }

        return nil
    }

    // MARK: - 브랜드명 한국어 변환 (단일)

    static func koreanBrand(for brand: String) -> String {
        if containsKorean(brand) { return brand }
        return brandToKorean[brand] ?? brand
    }
}
