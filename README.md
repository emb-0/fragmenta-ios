# Fragmenta iOS

Fragmenta iOS is the standalone native SwiftUI client for `fragmenta-core`, the separate Next.js backend that stores books and Kindle highlights. This repository is intentionally a real native iOS codebase, not a web wrapper, not React Native, and not Expo.

Sprint 1 establishes the app shell, production-minded architecture, typed backend contracts, premium design system, and core reading surfaces so the project is immediately useful once opened in Xcode.

## Sprint 1 goals

- Mirror the premium journal aesthetic from `../ephemeride-ios/Ephemeride/Core/DesignSystem/`
- Build a real SwiftUI app entry and navigation shell
- Add typed models and a configurable backend client for `fragmenta-core`
- Scaffold polished Library, Book Detail, Search, Import, and Settings screens
- Keep mocks isolated to previews only
- Leave a clean path for future auth, offline support, richer import flows, and search refinement

## Design system inheritance

Fragmenta reuses the sibling app's visual language by porting the same:

- Liquid glass support patterns from `LiquidGlassSupport.swift`
- typography scale and rounded editorial hierarchy
- dark premium palette and restrained surface layering
- spacing and radius proportions that make the interface feel like the same product family

Files live in [`Fragmenta/DesignSystem`](./Fragmenta/DesignSystem).

## What was scaffolded

### App shell

- `FragmentaApp.swift` with SwiftUI app entry
- `RootView.swift` with native tab navigation
- `AppState.swift` for lightweight shared tab state
- `AppContainer.swift` for dependency wiring

### Models

- `AppConfig`
- `Book`
- `BookDetail`
- `Highlight`
- `HighlightSearchResult`
- `ImportRequest`
- `ImportResponse`
- `APIError`

### Networking and services

- generic `APIClient`
- typed `APIEndpoint` builders
- future-friendly request header provider seam for auth later
- `BooksService`
- `SearchService`
- `HighlightService`

### Feature screens

- `LibraryView`
- `BookDetailView`
- `SearchView`
- `ImportView`
- `SettingsView`
- premium `HighlightCardView`
- feature-specific view models for async loading and UI state

### Preview-only support

- `PreviewFixtures.swift`
- `PreviewContainer.swift`

No fake demo logic was added to production services.

## Important file tree

```text
fragmenta-ios/
├── Config/
│   ├── Base.xcconfig
│   ├── Debug.xcconfig
│   ├── Release.xcconfig
│   └── Info.plist
├── Fragmenta/
│   ├── App/
│   ├── Core/
│   ├── DesignSystem/
│   ├── Features/
│   │   ├── Highlights/
│   │   ├── Import/
│   │   ├── Library/
│   │   ├── Search/
│   │   └── Settings/
│   ├── Models/
│   ├── Resources/
│   ├── Services/
│   │   └── API/
│   └── Utilities/
│       └── PreviewSupport/
├── Fragmenta.xcodeproj
├── project.yml
└── README.md
```

## Expected backend contract with fragmenta-core

Sprint 1 assumes `fragmenta-core` exposes a public JSON API with a `data` envelope on successful responses and an `error` envelope on failures.

### Success envelope

```json
{
  "data": {}
}
```

### Error envelope

```json
{
  "error": {
    "code": "string_code",
    "message": "Human readable message",
    "details": "Optional detail",
    "request_id": "Optional trace id"
  }
}
```

### Endpoint assumptions

#### `GET /api/books`

```json
{
  "data": [
    {
      "id": "bk_123",
      "title": "Book title",
      "author": "Author name",
      "source": "kindle_export",
      "highlight_count": 42,
      "cover_url": null,
      "synopsis": "Optional summary",
      "last_imported_at": "2026-04-08T12:00:00Z",
      "created_at": "2026-04-01T12:00:00Z",
      "updated_at": "2026-04-08T12:00:00Z"
    }
  ]
}
```

#### `GET /api/books/{id}`

```json
{
  "data": {
    "book": {
      "id": "bk_123",
      "title": "Book title",
      "author": "Author name",
      "source": "kindle_export",
      "highlight_count": 42,
      "cover_url": null,
      "synopsis": "Optional summary",
      "last_imported_at": "2026-04-08T12:00:00Z",
      "created_at": "2026-04-01T12:00:00Z",
      "updated_at": "2026-04-08T12:00:00Z"
    },
    "stats": {
      "highlight_count": 42,
      "note_count": 3,
      "last_imported_at": "2026-04-08T12:00:00Z"
    }
  }
}
```

#### `GET /api/books/{id}/highlights`

```json
{
  "data": [
    {
      "id": "hl_123",
      "book_id": "bk_123",
      "text": "Highlighted passage",
      "note": "Optional note",
      "location": 512,
      "page": null,
      "chapter": "Optional chapter",
      "color_name": null,
      "highlighted_at": "2026-04-08T12:00:00Z",
      "created_at": "2026-04-08T12:00:00Z",
      "book": null
    }
  ]
}
```

#### `GET /api/search?q=`

```json
{
  "data": [
    {
      "highlight": {
        "id": "hl_123",
        "book_id": "bk_123",
        "text": "Highlighted passage",
        "note": null,
        "location": 512,
        "page": null,
        "chapter": "Optional chapter",
        "color_name": null,
        "highlighted_at": "2026-04-08T12:00:00Z",
        "created_at": "2026-04-08T12:00:00Z",
        "book": null
      },
      "book": {
        "id": "bk_123",
        "title": "Book title",
        "author": "Author name"
      },
      "matched_terms": ["passage"]
    }
  ]
}
```

#### `POST /api/imports/kindle`

Request body:

```json
{
  "source": "kindle_txt",
  "raw_text": "Full Kindle export text",
  "filename": "kindle-highlights.txt",
  "dry_run": false
}
```

Response:

```json
{
  "data": {
    "import_id": "imp_123",
    "status": "completed",
    "books_created": 1,
    "books_updated": 0,
    "highlights_imported": 32,
    "duplicate_highlights": 0,
    "warnings": [],
    "message": "Import completed"
  }
}
```

### Serialization assumptions

- keys are `snake_case`
- dates are ISO8601 strings
- endpoints are public in Sprint 1
- auth can be added later through the request headers provider without reworking the API client

## Networking configuration

`AppConfig` reads the backend origin from `FragmentaAPIBaseURL` in `Info.plist`, which is populated from xcconfig files:

- `Config/Debug.xcconfig`
- `Config/Release.xcconfig`

Important: the base URL should be the backend origin, not a full endpoint path. The client appends `/api/...` itself.

Default values:

- Debug: `http://127.0.0.1:3000`
- Release: `https://fragmenta-core.example.com`

If your backend runs on a different host or port, update those files before running the app.

## What still requires Xcode

This repo includes generated Swift source and an `Fragmenta.xcodeproj`, but you will still need Xcode for:

- actual compile validation
- code signing and team selection
- simulator or device runs
- adding a real app icon set
- adjusting deployment target or bundle settings if your local setup differs

I did not attempt simulator tests or an Xcode build in this environment.

## How to open and run later in Xcode

1. Install Xcode on your MacBook.
2. Open this repo: `~/claude/Code/fragmenta-ios`
3. Optional but recommended: regenerate the project with `xcodegen generate`
4. Open `Fragmenta.xcodeproj`
5. In the target settings, set your `Development Team`
6. Confirm or change `PRODUCT_BUNDLE_IDENTIFIER` in `Config/Base.xcconfig`
7. Set the correct backend origin in `Config/Debug.xcconfig` and `Config/Release.xcconfig`
8. If you are hitting a non-HTTPS local backend, keep using the debug config and verify ATS behavior matches your setup
9. Select an iPhone simulator or device
10. Build and run

## Config values you need to set

- `FRAGMENTA_API_BASE_URL` in `Config/Debug.xcconfig`
- `FRAGMENTA_API_BASE_URL` in `Config/Release.xcconfig`
- `PRODUCT_BUNDLE_IDENTIFIER` in `Config/Base.xcconfig` if you want a custom identifier
- `DEVELOPMENT_TEAM` in Xcode target settings or xcconfig if you prefer checking it in locally

## Assumptions made

- `fragmenta-core` is the source of truth for parsing, persistence, and search
- the iOS app should never parse Kindle exports as business logic beyond packaging raw text for upload
- public unauthenticated access is acceptable in Sprint 1
- book detail metadata and highlight lists may come from separate endpoints
- the backend returns either a `data` envelope or an `error` envelope
- the backend can return `book` references inside search results

## Sprint 2 recommendations

- add file importer and share-sheet ingestion for Kindle `.txt` files
- support deep-linking from search results to specific highlights inside a book
- add response caching and offline-read support
- add import history and retry UX
- introduce authentication once `fragmenta-core` requires it
- refine search with filters for book, author, and date
- add pagination or incremental loading for large libraries
- add a real icon, launch screen polish, and haptic finishing touches

## Regenerating the project

This repo includes both the checked-in project and the manifest that generated it:

- `Fragmenta.xcodeproj`
- `project.yml`

If target settings drift, run:

```bash
xcodegen generate
```

That will rebuild the project from the manifest without touching your Swift source.
