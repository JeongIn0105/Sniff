# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an Xcode project. Open `Sniff.xcodeproj` and build/run with Xcode (⌘R). There is no CLI build, lint, or test command — all development is done through Xcode.

## API Keys Setup

Before building, copy `Sniff/Config/Secrets.xcconfig.example` to `Sniff/Config/Secrets.xcconfig` and fill in the real keys:

```
FRAGELLA_API_KEY = <your key>
GEMINI_API_KEY   = <your key>
```

`Secrets.xcconfig` is gitignored. Keys are read at runtime via `AppSecrets.geminiAPIKey()` / `AppSecrets.fragellaAPIKey()`, which pull from `Info.plist` entries injected by the xcconfig. Never hardcode keys directly in source.

## Architecture

Clean Architecture with MVVM-style presentation layer.

```
Domain/          ← protocols, models, use cases (no external imports)
Data/            ← concrete implementations
  Remote/API/    ← Fragella (perfume catalog), Gemini (taste analysis + name translation)
  Remote/Firebase/ ← FirestoreService (user data), AuthService
  Local/         ← CoreData (tasting notes), UserDefaults (search history, Fragella cache)
  Repository/    ← bridges Domain protocols to Data services
Presentation/
  common/Tab/    ← one folder per screen (Home, Search, TastingNote, MyPage, PerfumeDetail, Onboarding, Login, Settings, Splash)
  common/Components/ ← shared SwiftUI views
  common/DesignSystem/ ← Color/Font extensions (Color.sniffBeige, Font.sniffTitle, etc.)
App/
  AppStateManager.swift   ← top-level state machine (splash→login→onboarding→main)
  DI/AppDependencyContainer.swift ← singleton DI root; SceneFactory files wire VMs
Localization/
  UIStrings/AppStrings+*.swift    ← all user-facing strings
  PerfumeTranslation/             ← Korean transliteration dictionary
```

## Dependency Injection

`AppDependencyContainer.shared` is the single DI root. Singletons (`AuthService`, `FirestoreService`, `CoreDataStack`) are lazy properties. Per-request objects are created by `make*()` factory methods. Each screen gets a `*SceneFactory` in `App/DI/` that calls the container and passes dependencies to the ViewModel.

## Data Flow

- **Recommendation**: `RecommendPerfumesUseCase` → `RecommendationEngine` (RxSwift `Single`) → `PerfumeScorer` scores candidates from `PerfumeCatalogRepository` (backed by `FragellaService`).
- **Tasting notes**: `LocalTastingNoteRepository` writes to CoreData first, then syncs to Firestore's `users/{uid}/tastingRecords`. Sync status transitions: `pending` → `synced` / `failed`.
- **Taste analysis**: After saving enough tasting records (≥5, memo ≥20 chars), `LocalTastingNoteRepository` triggers `UserTasteRepository.reanalyzeTasteFromHistory()`, which calls `GeminiTasteAnalysisService` and persists the result to Firestore.
- **Perfume name translation**: `PerfumeNameTranslationService` — local dictionary first, Gemini fallback for unknowns. Results are in-memory cached.

## Reactive Pattern

`RecommendationEngine` and `FragellaService` use **RxSwift** (`Single`). All other async work uses **Swift Concurrency** (`async/await`). When bridging RxSwift to async contexts, use `RxSwift+Async.swift` helpers.

## Firestore Schema

User document: `users/{uid}` with sub-collections:
- `collection/` — owned perfumes
- `likes/` — liked perfumes
- `tastingRecords/` — synced tasting notes

Firestore security rules reject `null` optional fields, so `nil` Swift optionals must be omitted from write dictionaries entirely (not set to `NSNull`).

## Localization

All UI strings live in `Localization/UIStrings/AppStrings+*.swift`. Add new strings there, not inline. Korean transliteration data is split across `PerfumeKoreanTranslator+Data.swift` (word/brand dictionaries) and `PerfumeKoreanTranslator+Logic.swift` (matching logic).
