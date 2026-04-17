//
//  PerfumeNameTranslationService.swift
//  Sniff
//
//  Created by 이정인 on 2026.04.16.
//

import Foundation

// MARK: - 향수명 한국어 음역 서비스
// 1차: 로컬 단어 사전 (네트워크 불필요, 즉시 반환)
// 2차: Gemini API (사전에 없는 단어 보완, 백그라운드 캐시)

enum PerfumeNameTranslationService {

    // MARK: - 캐시

    private static var cache: [String: String] = [:]
    private static let geminiKey = "AIzaSyBO9QNecTKHP80WCC3XEoqAH4hTgr3vC7c"

    // MARK: - 번역 진입점

    static func translate(names: [String]) async throws -> [String: String] {
        var result: [String: String] = [:]

        // 1단계: 로컬 사전으로 즉시 번역 (캐시 포함)
        var needGemini: [String] = []
        for name in names {
            if let cached = cache[name] {
                result[name] = cached
            } else {
                let local = localTransliterate(name)
                cache[name] = local
                result[name] = local
                // 로컬 결과가 원문과 동일하면 Gemini로 보완 시도
                if local == name { needGemini.append(name) }
            }
        }

        // 2단계: Gemini로 미번역 항목 보완 (실패해도 무시)
        if !needGemini.isEmpty {
            if let geminiResult = try? await callGemini(names: needGemini, apiKey: geminiKey) {
                for (name, korean) in geminiResult where !korean.isEmpty {
                    cache[name] = korean
                    result[name] = korean
                }
            }
        }

        return result
    }

    // MARK: - 로컬 단어사전 번역

    static func localTransliterate(_ name: String) -> String {
        // 특수문자(&, -) 기준으로 분리 후 각각 번역
        let segments = name.components(separatedBy: CharacterSet(charactersIn: "&"))
        let translated = segments.map { seg -> String in
            let trimmed = seg.trimmingCharacters(in: .whitespaces)
            return transliterateSegment(trimmed)
        }
        return translated.joined(separator: " & ")
    }

    private static func transliterateSegment(_ text: String) -> String {
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var result: [String] = []
        var i = 0

        // 최대 3단어 브랜드명 prefix 매칭 (예: "Jo Malone", "Tom Ford")
        while i < words.count {
            var matched = false
            for len in stride(from: min(3, words.count - i), through: 1, by: -1) {
                let phrase = words[i..<(i + len)].joined(separator: " ")
                if let korean = PerfumeKoreanTranslator.brandToKorean[phrase] {
                    result.append(korean)
                    i += len
                    matched = true
                    break
                }
                // 소문자로도 시도
                let phraseLower = phrase.lowercased()
                    .components(separatedBy: " ")
                    .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                    .joined(separator: " ")
                if let korean = PerfumeKoreanTranslator.brandToKorean[phraseLower] {
                    result.append(korean)
                    i += len
                    matched = true
                    break
                }
            }
            if !matched {
                result.append(transliterateWord(words[i]))
                i += 1
            }
        }
        return result.joined(separator: " ")
    }

    private static func transliterateWord(_ word: String) -> String {
        let lower = word.lowercased()
        // 숫자가 포함된 단어는 그대로 유지 (No.5, EdP100 등)
        if word.contains(where: { $0.isNumber }) { return word }
        // 특수문자만으로 이루어진 단어도 그대로
        if word.allSatisfy({ !$0.isLetter }) { return word }
        // 1) wordDict 완전 일치
        if let found = wordDict[lower] { return found }
        // 2) 브랜드 사전 단일 단어 (예: "Creed", "Byredo")
        let capitalized = word.prefix(1).uppercased() + word.dropFirst().lowercased()
        if let found = PerfumeKoreanTranslator.brandToKorean[capitalized] { return found }
        if let found = PerfumeKoreanTranslator.brandToKorean[word] { return found }
        // 3) 복수형 처리
        if lower.hasSuffix("ies"), let base = wordDict[String(lower.dropLast(3)) + "y"] { return base + "스" }
        if lower.hasSuffix("es"), lower.count > 4, let base = wordDict[String(lower.dropLast(2))] { return base + "스" }
        if lower.hasSuffix("s"), lower.count > 4, let base = wordDict[String(lower.dropLast())] { return base + "스" }
        // 4) 소문자 한 글자는 유지 (de, le, la, un 등)
        if word.count <= 2 { return word }
        // 5) 폴백: 영문 그대로 (Gemini 보완 대상)
        return word
    }

    // MARK: - 단어 사전 (향수 이름에 자주 나오는 단어 300+)

    private static let wordDict: [String: String] = [
        // ── 크리드 향수 ──
        "aventus": "어벤투스", "himalaya": "히말라야", "carmina": "카르미나",
        "tabarome": "타바롬", "erolfa": "에롤파", "delphinus": "델피너스",
        "millesime": "밀레짐", "imperiale": "임페리알레", "bois": "부아",
        "du": "뒤", "portugal": "포르투갈", "spice": "스파이스",
        "silver": "실버", "mountain": "마운틴", "water": "워터",
        "green": "그린", "irish": "아이리쉬", "tweed": "트위드",
        "viking": "바이킹", "sublime": "서블라임",

        // ── 조 말론 ──
        "variety": "버라이어티", "grapefruit": "그레이프프루트",
        "waterlily": "워터릴리", "waterlilies": "워터릴리스",
        "garden": "가든", "hyacinth": "하이아신스",
        "tobacco": "타바코", "mandarin": "만다린", "bergamot": "베르가못",
        "lilies": "릴리스", "lily": "릴리", "blue": "블루",
        "peony": "피오니", "suede": "스웨이드", "oak": "오크",
        "oud": "우드", "myrrh": "몰약", "incense": "인센스",
        "nectarine": "넥터린", "blossom": "블로섬",
        "orange": "오렌지", "bitters": "비터스", "earl": "얼",
        "grey": "그레이", "gray": "그레이", "english": "잉글리쉬",
        "pear": "페어", "freesia": "프리지아",
        "pomegranate": "포메그라닛", "chilli": "칠리",
        "lime": "라임", "basil": "바질", "mandarine": "만다린",
        "velvet": "벨벳", "rose": "로즈", "petals": "페탈스",
        "cologne": "콜론",

        // ── 공통 향수 단어 ──
        "floral": "플로럴", "fresh": "프레시", "sweet": "스위트",
        "wood": "우드", "woods": "우즈", "forest": "포레스트",
        "aqua": "아쿠아", "ocean": "오션", "sea": "씨",
        "coconut": "코코넛", "summer": "써머", "spring": "스프링",
        "winter": "윈터", "autumn": "오텀", "night": "나이트",
        "day": "데이", "black": "블랙", "white": "화이트",
        "gold": "골드", "golden": "골든", "royal": "로열",
        "intense": "인텐스", "extreme": "익스트림",
        "absolute": "앱솔루트", "collection": "컬렉션",
        "edition": "에디션", "limited": "리미티드",
        "special": "스페셜", "signature": "시그니처",

        // ── 숫자/서수 ──
        "no": "넘버", "no.": "넘버", "number": "넘버",
        "one": "원", "two": "투", "three": "쓰리",
        "four": "포", "five": "파이브", "six": "식스",
        "seven": "세븐", "eight": "에이트", "nine": "나인",
        "ten": "텐", "first": "퍼스트",

        // ── 프랑스어 ──
        "noir": "누아르", "blanc": "블랑", "rouge": "루즈",
        "vert": "베르", "pour": "뿌르", "homme": "옴므",
        "femme": "팜므", "enfants": "앙팡", "eau": "오",
        "parfum": "파르팡", "toilette": "뚜왈렛",
        "le": "르", "la": "라", "les": "레", "de": "드",
        "des": "데", "un": "앙", "une": "윈",
        "belle": "벨", "beau": "보", "cher": "셰르",
        "fleur": "플뢰르", "fleurs": "플뢰르", "soleil": "솔레이",
        "nuit": "뉘", "jour": "주르", "monde": "몽드",
        "jardin": "자르당", "sauvage": "소바쥬", "bleu": "블루",
        "chance": "찬스", "coco": "코코", "allure": "알뤼르",
        "mademoiselle": "마드모아젤", "miss": "미스",
        "etoile": "에투왈", "ambre": "앙브르",
        "neroli": "네롤리", "gardenia": "가르드니아",
        "santal": "상탈", "encens": "앙상",
        "tabac": "타박", "figue": "피그", "vetiver": "베티버",
        "patchouli": "패출리", "cedre": "세드르", "iris": "이리스",
        "vanille": "바닐", "musc": "뮈스크",

        // ── 이탈리아어/스페인어 ──
        "acqua": "아쿠아", "di": "디", "gio": "지오",
        "profumo": "프로푸모", "intensa": "인텐사",
        "absolu": "앱솔루", "lumiere": "뤼미에르",
        "terra": "테라", "futura": "푸투라",
        "bella": "벨라", "bello": "벨로", "vita": "비타",
        "amor": "아모르", "rosa": "로사", "fiore": "피오레",

        // ── 자연 ──
        "cedar": "시더", "sandalwood": "샌달우드",
        "lavender": "라벤더", "jasmine": "재스민",
        "violet": "바이올렛", "amber": "앰버",
        "musk": "머스크", "vanilla": "바닐라",
        "citrus": "시트러스",
        "lemon": "레몬", "peach": "피치", "cherry": "체리",
        "apple": "애플", "plum": "플럼",
        "fig": "피그", "pomelo": "포멜로", "yuzu": "유즈",
        "yuja": "유자", "ginger": "진저", "pepper": "페퍼",
        "cardamom": "카다멈", "cinnamon": "시나몬", "clove": "클로브",
        "nutmeg": "넛메그", "saffron": "사프란",
        "heliotrope": "헬리오트로프", "tuberose": "튜베로즈",
        "magnolia": "마그놀리아", "mimosa": "미모사",
        "carnation": "카네이션", "orchid": "오키드",
        "lotus": "로터스", "wisteria": "위스테리아",
        "honeysuckle": "허니서클", "hawthorn": "호손",
        "elderflower": "엘더플라워",
        "amyris": "아미리스", "guaiac": "과이악",
        "oakmoss": "오크모스",
        "labdanum": "라브다넘", "benzoin": "벤조인",
        "frankincense": "프랑킨센스",
        "tonka": "통카", "coumarin": "쿠마린",
        "mastic": "매스틱", "elemi": "엘레미",

        // ── 형용사/수식어 ──
        "wild": "와일드", "pure": "퓨어", "true": "트루",
        "real": "리얼", "natural": "네츄럴", "organic": "오가닉",
        "deep": "딥", "rich": "리치", "light": "라이트",
        "dark": "다크", "bright": "브라이트", "soft": "소프트",
        "hard": "하드", "warm": "웜", "cool": "쿨",
        "hot": "핫", "cold": "콜드", "new": "뉴", "old": "올드",
        "grand": "그랑", "great": "그레이트", "big": "빅",
        "fine": "파인", "good": "굿", "best": "베스트",
        "noble": "노블", "gentle": "젠틀", "divine": "디바인",
        "sacred": "세이크리드", "secret": "시크릿",
        "mysterious": "미스터리어스", "mystery": "미스터리",
        "magic": "매직", "dream": "드림", "legend": "레전드",
        "iconic": "아이코닉", "classic": "클래식",
        "modern": "모던", "urban": "어반", "luxury": "럭셔리",
        "elite": "엘리트", "premium": "프리미엄",
        "exclusive": "익스클루시브", "private": "프라이빗",

        // ── 공간/장소 ──
        "paris": "파리", "rome": "로마", "london": "런던",
        "milan": "밀란", "new york": "뉴욕", "tokyo": "도쿄",
        "orient": "오리엔트", "arabian": "아라비안",
        "persian": "페르시안", "moroccan": "모로칸",
        "island": "아일랜드", "river": "리버",
        "valley": "밸리", "coast": "코스트", "shore": "쇼어",

        // ── 기타 향수 고유명 ──
        "shalimar": "샬리마르", "opium": "오피움",
        "tresor": "트레조르", "miracle": "미라클",
        "hypnose": "이프노즈", "idole": "이돌",
        "la vie est belle": "라 비 에 벨",
        "j'adore": "자도르", "jadore": "자도르",
        "fahrenheit": "파렌하이트", "poison": "프와종",
        "obsession": "옵세션", "eternity": "이터니티",
        "euphoria": "유포리아", "contradiction": "콘트라딕션",
        "escapade": "에스카파드",
        "angel": "앙쥬", "alien": "에이리언",
        "flowerbomb": "플라워밤", "bonbon": "봉봉",
        "olympea": "올림피아", "invictus": "인빅투스",
        "elixir": "엘릭시르",
        "chanel": "샤넬", "dior": "디올",
        "versace": "베르사체", "prada": "프라다",
        "gucci": "구찌", "armani": "아르마니",
        "acqua di gio": "아쿠아 디 지오",
        "profondo": "프로폰도",
        "terra di gioia": "테라 디 조이아",

        // ── 추가 단어 ──
        "passiflora": "파시플로라", "passion": "파션",
        "fruit": "프루트", "fruity": "프루티",
        "berry": "베리", "berries": "베리스",
        "melon": "멜론", "watermelon": "워터멜론",
        "mango": "망고", "papaya": "파파야",
        "lychee": "리치", "guava": "구아바",
        "passion fruit": "패션 프루트",
        "tea": "티", "green tea": "그린 티",
        "chamomile": "카모마일", "mint": "민트",
        "thyme": "타임",
        "sage": "세이지", "rosemary": "로즈마리",
        "fennel": "펜넬", "anise": "아니스",
        "rum": "럼", "whisky": "위스키",
        "cognac": "코냑", "bourbon": "버번",
        "leather": "레더",
        "canvas": "캔버스",
        "linen": "리넨", "silk": "실크",
        "cotton": "코튼", "cashmere": "캐시미어",
        "powder": "파우더", "powdery": "파우더리",
        "smoke": "스모크", "smoky": "스모키",
        "earth": "어스", "earthy": "어시",
        "stone": "스톤", "rock": "록",
        "mineral": "미네럴", "salt": "솔트",
        "sea salt": "씨 솔트", "driftwood": "드리프트우드",
        "coral": "코랄", "reef": "리프",
        "sun": "썬", "sunshine": "선샤인",
        "moon": "문", "moonlight": "문라이트",
        "star": "스타", "starlight": "스타라이트",
        "dawn": "던", "dusk": "더스크",
        "rain": "레인", "storm": "스톰",
        "breeze": "브리즈", "wind": "윈드",
        "fire": "파이어", "flame": "플레임",
        "ice": "아이스", "snow": "스노우",
        "cloud": "클라우드", "sky": "스카이",
        "heaven": "헤븐", "paradise": "파라다이스",


        // ── 조 말론 추가 단어 ──
        "blackberry": "블랙베리", "bay": "베이", "coriander": "코리앤더",
        "osmanthus": "오스만투스", "poppy": "포피", "barley": "발리",
        "scarlet": "스칼렛", "moonlit": "문릿",
        "camomile": "카모마일",   // chamomile 대안 철자

        // ── 크리드 추가 ──
        "fleurissimo": "플뢰리시모", "floralie": "플로라리",
        "centaurus": "센타우루스",
        "selection": "셀렉션", "verte": "베르트",
        "tubereuse": "튜베르즈", "indiana": "인디아나",

        // ── 일반 향수 추가 단어 ──
        "cascade": "카스케이드", "florale": "플로라레",
        "olympia": "올림피아",
        "rive": "리브", "gauche": "고쉬",
        "libre": "리브르",
        "profundo": "프로푼도", "eros": "에로스",
        "dylan": "딜런",
        "crystal": "크리스탈", "diamond": "다이아몬드",
        "ruby": "루비", "emerald": "에메랄드",
        "horizon": "호라이즌", "echo": "에코",
        "spirit": "스피릿",
        "soul": "소울", "heart": "하트",
        "voyage": "보야쥬", "aventure": "아방튀르",
        "nomad": "노마드", "wanderer": "원더러",
        "explorer": "익스플로러", "pioneer": "파이어니어",
        // ── 향수 유형 ──
        "edt": "EDT", "edp": "EDP", "edc": "EDC",
        "extrait": "엑스트레", "forte": "포르테",
    ]

    // MARK: - Gemini API 호출 (보완용)

    private static func callGemini(names: [String], apiKey: String) async throws -> [String: String] {
        let models = ["gemini-2.0-flash", "gemini-1.5-flash"]
        for model in models {
            if let result = try? await callGeminiModel(model: model, names: names, apiKey: apiKey),
               !result.isEmpty { return result }
        }
        throw TranslationError.apiError
    }

    private static func callGeminiModel(model: String, names: [String], apiKey: String) async throws -> [String: String] {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw TranslationError.invalidURL }

        let nameList = names.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        let prompt = """
        아래 향수 이름들을 한국어 발음 표기(음역)로 변환해줘.
        반드시 입력과 동일한 순서로 JSON 문자열 배열만 응답해. 마크다운 없이 순수 JSON만.
        예시: ["조 말론 버라이어티", "크리드 어벤투스"]

        번역할 목록:
        \(nameList)
        """

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 25
        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": ["temperature": 0.1]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else { throw TranslationError.apiError }

        guard
            let json       = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let content    = candidates.first?["content"] as? [String: Any],
            let parts      = content["parts"] as? [[String: Any]],
            var text       = parts.first?["text"] as? String
        else { throw TranslationError.parsingFailed }

        if text.contains("```") {
            text = text.replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let s = text.firstIndex(of: "["), let e = text.lastIndex(of: "]") {
            text = String(text[s...e])
        }
        guard let arrayData = text.data(using: .utf8),
              let koreanNames = try? JSONSerialization.jsonObject(with: arrayData) as? [String]
        else { throw TranslationError.parsingFailed }

        var result: [String: String] = [:]
        for (i, name) in names.enumerated() where i < koreanNames.count {
            let korean = koreanNames[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if !korean.isEmpty { result[name] = korean }
        }
        return result
    }

    enum TranslationError: Error { case invalidURL, apiError, parsingFailed }
}
