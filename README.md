# 킁킁 (Sniff)

> 킁킁은 향수를 잘 몰라도 나의 취향에 맞는 향수를 쉽게 찾고, 시향 경험을 기록할 수 있는 iOS 앱입니다.

---

<p align="center">
  <img src="https://github.com/user-attachments/assets/8c450aac-25a7-4e7a-9541-3ed50b6eba4c" alt="Sniff Cover" width="1000" />
</p>

## 📋 프로젝트 개요

**킁킁 Sniff**는 사용자의 향 취향을 기반으로 향수를 추천하고, 시향 기록과 보유 향수를 관리할 수 있는 향수 추천 및 기록 서비스입니다.

향수를 처음 접하는 사용자는 어떤 향수가 자신에게 맞는지 알기 어렵고, 직접 시향한 향수를 체계적으로 기록하기도 쉽지 않습니다.  
킁킁은 취향 온보딩과 Gemini AI 기반 취향 프로필을 통해 사용자의 향 취향을 분석하고, 취향에 맞는 향수를 추천합니다.

또한 시향기, 보유 향수, LIKE 향수를 분리해 관리할 수 있도록 하여 사용자가 자신의 향수 취향을 지속적으로 기록하고 발전시킬 수 있도록 돕습니다.

---

## 🎯 서비스 목표

- 향수를 잘 모르는 사용자도 쉽게 자신의 취향을 파악할 수 있도록 지원
- 사용자 취향 기반 향수 추천 경험 제공
- 시향한 향수와 보유 향수를 체계적으로 기록할 수 있는 환경 제공
- 향수 검색, 상세 정보, 추천 기능을 통해 향수 탐색 과정 개선

---

## 👤 대상 사용자

- 향수를 좋아하지만 어디서부터 시작해야 할지 모르는 사용자
- 나에게 어울리는 향수를 추천받고 싶은 사용자
- 시향한 향수를 기록하고 다시 확인하고 싶은 사용자
- 보유 향수와 관심 향수를 분리해서 관리하고 싶은 사용자
- 향수 노트, 계열, 브랜드 정보를 쉽게 확인하고 싶은 사용자

---

## 👥 팀 구성

| 이름 | 역할 |
| --- | --- |
| 우현진 | iOS 앱 개발자 | 
| 이정인 | iOS 앱 개발자 | 
| 전하연 | UX/UI 디자이너 | 

---

## ⏰ 프로젝트 일정

- **프로젝트 기간**: 26.03.31 ~ 26.05.07

---

## 🛠️ 기술 스택

### Language
- Swift

### 아키텍처
- MVVM
- Repository Pattern

### UI
- UIKit
- AutoLayout

### Reactive / Async
- RxSwift
- Swift Concurrency

### Local Data
- CoreData
- UserDefaults

### Backend / Auth
- Firebase Authentication
- Cloud Firestore

### AI / External API
- Gemini API
- Fragella API

### Version Control
- Git
- GitHub

---

## 📱 주요 기능

### 1. 소셜 로그인

- Apple 로그인 지원
- Google 로그인 지원
- Firebase Authentication 기반 사용자 인증 처리

---

### 2. 취향 온보딩

사용자는 온보딩 과정에서 선호하는 향, 분위기, 이미지 등을 선택할 수 있습니다.

이를 바탕으로 사용자의 향수 취향을 분석하고, 개인화 추천에 활용합니다.

---

### 3. Gemini AI 기반 취향 프로필

온보딩 결과를 기반으로 Gemini AI를 활용해 사용자의 향 취향을 자연어로 정리합니다.

사용자는 자신의 취향을 한눈에 확인할 수 있으며, 마이페이지에서 취향 프로필을 다시 확인할 수 있습니다.

---

### 4. 취향 기반 향수 추천

사용자의 취향 정보를 바탕으로 향수를 추천합니다.

- 취향 맞춤 향수 추천
- 인기 맞춤 향수 추천
- 홈 화면 추천 리스트 제공
- 추천 향수 상세 정보 확인

---

### 5. 향수 검색 및 필터

Fragella API 기반 향수 데이터를 활용해 향수를 검색할 수 있습니다.

- 향수명 검색
- 브랜드명 검색
- 최근 검색어 제공
- 필터 기능 제공
- 검색 결과에서 상세 정보 이동

---

### 6. 향수 상세 정보

향수 상세 화면에서 향수의 기본 정보를 확인할 수 있습니다.

- 향수명
- 브랜드명
- 향 계열
- 노트 정보
- 계절감
- 분위기 및 이미지
- 향수 설명

---

### 7. 시향기 기록

사용자가 직접 시향한 향수를 기록할 수 있습니다.

- 향수명 입력
- 브랜드명 입력
- 향 선호도 선택
- 분위기 및 이미지 선택
- 시향 메모 작성
- 보유 향수 사용 기록 작성

---

### 8. 보유 향수 관리

사용자가 실제로 보유한 향수를 등록하고 관리할 수 있습니다.

- 보유 향수 등록
- 보유 향수 정보 수정
- 보유 향수 목록 관리
- 시향기 작성 시 보유 향수 연결

---

### 9. LIKE 향수 관리

관심 있는 향수를 LIKE 향수로 저장할 수 있습니다.

보유 향수와 LIKE 향수를 분리해 관리함으로써 사용자가 실제 보유한 향수와 관심 향수를 명확히 구분할 수 있습니다.

---

### 10. 마이페이지

마이페이지에서 사용자의 향수 관련 데이터를 한눈에 확인할 수 있습니다.

- 취향 프로필 확인
- 보유 향수 확인
- LIKE 향수 확인
- 시향기 기록 확인

---

## 🔄 앱 업데이트 내용

이번 버전에서는 향수 추천과 기록 경험을 전반적으로 개선했습니다.

- Google 계정으로 로그인할 수 있도록 개선
- 취향 온보딩과 취향 프로필 화면 개선
- 홈 추천 화면에서 취향 맞춤 향수와 인기 맞춤 추천을 더 쉽게 확인할 수 있도록 개선
- 보유 향수 등록 및 정보 수정 기능 추가
- 시향기에서 보유 향수 사용 기록을 작성할 수 있도록 개선
- LIKE 향수와 보유 향수를 분리해 관리할 수 있도록 개선
- 향수 검색, 최근 검색어, 필터 기능 개선
- 향수 상세 화면의 정보 구성을 더 보기 쉽게 개선
- 전반적인 UI와 앱 안정성 개선

---

## 🧩 프로젝트 구조

```bash
Sniff
├── Data
│   ├── Local
│   ├── Remote
│   └── Repository
│
├── Domain
│   ├── Model
│   ├── UseCase
│   └── Recommendation
│
├── Presentation
│   ├── common
│   ├── Home
│   ├── Search
│   ├── PerfumeDetail
│   ├── TastingNote
│   ├── MyPerfume
│   └── MyPage
│
├── Localization
│   └── PerfumeTranslation
│
├── Config
│   └── Secrets.xcconfig
│
└── GoogleService-Info.plist
```

---

## 🔐 환경 설정

이 프로젝트는 외부 API와 Firebase를 사용하기 때문에 아래 파일이 필요합니다.

```bash
Sniff/GoogleService-Info.plist
Sniff/Config/Secrets.xcconfig
```

보안상 해당 파일들은 GitHub에 업로드하지 않습니다.

`.gitignore`에 아래 파일들을 추가해 민감 정보가 원격 저장소에 올라가지 않도록 관리합니다.

```gitignore
# Sniff / config / secrets
Sniff/GoogleService-Info.plist
Sniff/Config/Secrets.xcconfig
```

`Secrets.xcconfig` 예시:

```bash
GEMINI_API_KEY = YOUR_GEMINI_API_KEY
FRAGELLA_API_KEY = YOUR_FRAGELLA_API_KEY
```

---

## 📦 설치 및 실행 방법

1. 저장소를 클론합니다.

```bash
git clone https://github.com/사용자명/Sniff.git
```

2. 프로젝트 폴더로 이동합니다.

```bash
cd Sniff
```

3. Firebase 설정 파일을 추가합니다.

```bash
Sniff/GoogleService-Info.plist
```

4. API Key 설정 파일을 추가합니다.

```bash
Sniff/Config/Secrets.xcconfig
```

5. Xcode에서 프로젝트를 실행합니다.

```bash
open Sniff.xcodeproj
```

또는 워크스페이스를 사용하는 경우:

```bash
open Sniff.xcworkspace
```

---

## 🧪 트러블 슈팅

### 1. 향수 DB 확보 문제

#### 문제

초기에는 직접 향수 데이터 약 200개를 만들고, 향수 이미지는 사용자가 직접 입력하는 방식으로 구현하려고 했습니다.

하지만 향수를 추천하는 서비스에서 향수 이미지와 상세 정보가 부족하면 사용자가 향수를 직관적으로 이해하기 어렵다는 문제가 있었습니다.

#### 원인

향수 데이터는 이미지, 브랜드명, 향수명, 향 계열, 노트, 농도, 계절감 등 다양한 정보가 필요했습니다.

직접 데이터를 구축하는 방식은 데이터 양과 품질을 안정적으로 확보하기 어려웠습니다.

#### 해결

Fragella API를 도입하여 향수 데이터를 받아오고, 앱 화면에서 필요한 정보 중심으로 구성했습니다.

이를 통해 사용자는 향수 검색, 추천, 상세 정보 화면에서 더 풍부한 정보를 확인할 수 있게 되었습니다.

---

### 2. Fragella API 데이터 한글화 문제

#### 문제

Fragella API는 영어 데이터를 기준으로 제공되어 국내 사용자에게 향수명과 브랜드명이 낯설게 느껴질 수 있었습니다.

또한 약 74,000개 이상의 데이터를 한 번에 모두 한글화하기에는 현실적으로 어려움이 있었습니다.

#### 원인

API에서 한국어 데이터를 제공하지 않았고, 모든 향수 데이터를 수동으로 번역하는 방식은 유지보수 비용이 매우 컸습니다.

#### 해결

국내 백화점 및 공식몰에서 실제로 사용하는 브랜드명과 향수명을 우선적으로 매핑하는 방식으로 해결했습니다.

매핑되지 않은 데이터는 원문을 유지하도록 처리하여 앱 안정성을 확보했습니다.

```swift
static func koreanBrand(for brand: String) -> String {
    let trimmed = brand.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return brand }

    if containsKorean(trimmed) { return trimmed }
    if let korean = brandToKorean[trimmed] { return korean }
    if let korean = lowerBrandToKorean[trimmed.lowercased()] { return korean }

    return normalizedBrandToKorean[normalizeBrandKey(trimmed)] ?? trimmed
}
```

#### 결과

- 영문 브랜드명을 바로 출력하지 않고 한글 매핑 여부를 먼저 확인
- 매핑된 데이터는 한글로 표시
- 매핑되지 않은 데이터는 원문 유지
- 홈, 검색, 상세, 시향기, 마이페이지에서 일관된 한글 표기 제공

---

### 3. API 키 및 설정 파일 GitHub 노출 문제

#### 문제

`GoogleService-Info.plist`, `Secrets.xcconfig`와 같은 민감한 설정 파일이 GitHub에 올라갈 수 있는 문제가 발생했습니다.

#### 원인

초기 설정 단계에서 `.gitignore`에 민감 파일을 미리 등록하지 않았고, 일부 파일이 Git 추적 대상에 포함될 수 있었습니다.

#### 해결 방법

민감 파일을 `.gitignore`에 추가하고, 이미 추적 중이던 파일은 Git 캐시에서 제거했습니다.

```gitignore
# Sniff / config / secrets
Sniff/GoogleService-Info.plist
Sniff/Config/Secrets.xcconfig
```

```bash
git rm --cached Sniff/GoogleService-Info.plist
git rm --cached Sniff/Config/Secrets.xcconfig

git add .gitignore
git commit -m "fix: 외부 API 키 및 설정 파일 gitignore 추가"
git push
```

#### 결과

- 민감 파일이 원격 저장소에 다시 올라가지 않도록 관리
- 노출 가능성이 있는 API 키 재발급
- Firebase 및 외부 API 설정 파일을 로컬에서만 관리하도록 개선

---

## ✅ 완성된 기능

### 로그인 & 취향 분석

- Apple / Google 소셜 로그인 연동
- 취향 온보딩 개선
- Gemini AI 기반 취향 프로필 생성

### 향수 추천 & 탐색

- 취향 맞춤 향수 추천
- 인기 맞춤 향수 추천
- 향수 검색, 최근 검색어, 필터 기능 개선
- 향수 상세 정보 화면 구성 개선

### 시향 기록 & 마이페이지

- 시향기 기록 및 저장
- 보유 향수 사용 기록 작성
- 보유 향수 등록 및 정보 수정
- LIKE 향수와 보유 향수 분리 관리

---

## 🚀 향후 개선 방향

- 다른 사용자 리뷰 기능 추가
- 향수 구매 링크 연결
- 커뮤니티 기능 도입
- 향수 추천 히스토리 제공

---

## 🔗 링크

| 구분 | 링크 |
| --- | --- |
| GitHub 링크 | https://github.com/JeongIn0105/Sniff |
| App Store 링크 | https://apps.apple.com/kr/app/%ED%82%81%ED%82%81-%ED%96%A5%EC%88%98-%EC%B6%94%EC%B2%9C-%ED%94%8C%EB%9E%AB%ED%8F%BC/id6763529466 |
| 브로셔 링크 | https://www.notion.so/teamsparta/iOS-9-34f2dc3ef51481a68e39e55d5a2d3488 |

---

## 📝 회고

이번 프로젝트를 통해 단순히 향수 정보를 보여주는 앱이 아니라, 사용자의 취향을 분석하고 추천과 기록으로 이어지는 서비스 흐름을 설계하는 경험을 할 수 있었습니다.

특히 향수 데이터 확보, Fragella API 데이터 한글화, Firebase 인증 및 데이터 동기화, 민감 정보 관리 등 실제 서비스 개발 과정에서 발생할 수 있는 문제를 직접 해결하며 iOS 앱 개발 전반의 흐름을 경험했습니다.

앞으로는 유저 피드백을 기반으로 리뷰, 커뮤니티, 향수 추천 히스토리 기능을 추가하여 사용자가 자신의 향수 취향을 더 깊이 탐색할 수 있는 서비스로 발전시키고자 합니다.
