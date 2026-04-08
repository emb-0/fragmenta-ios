# Fragmenta iOS

Fragmenta iOS is the standalone native SwiftUI client for `fragmenta-core`, the separate Next.js backend that stores Kindle-imported books, highlights, notes, imports, and exports.

This repository is intentionally:

- a real native iOS codebase in Swift and SwiftUI
- not a web wrapper
- not React Native
- not Expo
- not cross-platform scaffolding

Sprint 2 takes the Sprint 1 shell and turns it into a connected, caching-aware, production-minded app shell that is close to runnable the moment it is opened in Xcode.

## Sprint 2 snapshot

Sprint 2 adds:

- stronger app state and dependency wiring
- richer backend contracts and resilient decoding
- paginated library, book detail, and search flows
- debounced search with filter support
- real import preview and commit flows
- UIDocumentPicker-based `.txt` import plumbing
- import history fetching and detail inspection
- lightweight local persistence for cached responses and search memory
- export service hooks for markdown and CSV
- a more useful Settings screen with backend, cache, export, and diagnostics surfaces

The visual language still inherits the premium journal aesthetic from `../ephemeride-ios/Ephemeride/Core/DesignSystem/`, including the liquid-glass support, typography hierarchy, restrained palette, and calm material treatment.

## Architecture

### App shell

- `Fragmenta/App/FragmentaApp.swift`
- `Fragmenta/App/RootView.swift`
- `Fragmenta/Core/AppState.swift`
- `Fragmenta/Core/AppContainer.swift`

`AppState` owns lightweight tab state plus the live dependency container. `AppContainer` wires config, services, cache, preferences, and diagnostics together without bringing business logic into views.

### Core infrastructure

- `Fragmenta/Core/AppPreferencesStore.swift`
- `Fragmenta/Core/DiagnosticsStore.swift`
- `Fragmenta/Core/FragmentaCacheStore.swift`

Persistence is intentionally lightweight:

- JSON file cache in `Caches/FragmentaCache` for library data, book detail payloads, paged highlights, and import summaries
- `UserDefaults` for development base URL override, recent searches, and diagnostics snapshot

This is not an offline-sync engine. It is a pragmatic cache layer so the app feels less fragile when `fragmenta-core` is slow or temporarily unavailable.

### Services

- `Fragmenta/Services/BooksService.swift`
- `Fragmenta/Services/SearchService.swift`
- `Fragmenta/Services/ImportService.swift`
- `Fragmenta/Services/ExportService.swift`
- `Fragmenta/Services/API/APIClient.swift`
- `Fragmenta/Services/API/APIEndpoint.swift`

The service layer is structured for:

- async/await networking
- future auth/header injection without rewriting the client
- pagination
- request cancellation in view models
- backend error mapping into typed `APIError`
- cached fallback loading

### Feature areas

- `Fragmenta/Features/Library`
- `Fragmenta/Features/Highlights`
- `Fragmenta/Features/Search`
- `Fragmenta/Features/Import`
- `Fragmenta/Features/Settings`

Each feature owns its view model and screen state instead of pushing network orchestration into views.

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
│   │   ├── AppContainer.swift
│   │   ├── AppPreferencesStore.swift
│   │   ├── AppState.swift
│   │   ├── DiagnosticsStore.swift
│   │   └── FragmentaCacheStore.swift
│   ├── DesignSystem/
│   ├── Features/
│   │   ├── Highlights/
│   │   ├── Import/
│   │   │   └── KindleDocumentPicker.swift
│   │   ├── Library/
│   │   ├── Search/
│   │   └── Settings/
│   ├── Models/
│   │   ├── ExportArtifact.swift
│   │   ├── ImportPreview.swift
│   │   ├── ImportRecord.swift
│   │   ├── LibraryQuery.swift
│   │   ├── Pagination.swift
│   │   └── SearchQuery.swift
│   ├── Services/
│   │   ├── API/
│   │   ├── BooksService.swift
│   │   ├── ExportService.swift
│   │   ├── ImportService.swift
│   │   └── SearchService.swift
│   └── Utilities/
│       └── PreviewSupport/
├── Fragmenta.xcodeproj
├── project.yml
└── README.md
```

## Backend contract assumptions

Sprint 2 assumes the backend is public and unauthenticated.

Expected endpoints:

- `GET /api/books`
- `GET /api/books/{id}`
- `GET /api/books/{id}/highlights?page=&limit=`
- `GET /api/highlights/{id}`
- `GET /api/search?q=&book_id=&author=&has_notes=&sort=&page=&limit=`
- `POST /api/imports/kindle`
- `POST /api/imports/kindle/preview`
- `GET /api/imports`
- `GET /api/imports/{id}`
- `GET /api/exports/markdown`
- `GET /api/exports/csv`

### Success envelope

The client prefers a `data` envelope:

```json
{
  "data": {}
}
```

For paginated responses, the code is intentionally tolerant. It can decode:

- `data` as a plain array
- `data.items`
- `data.results`
- `data.highlights`
- `data.books`
- `data.imports`
- `data.records`

Pagination metadata is expected in one of these shapes:

- `pagination`
- `page_info`
- `pageInfo`
- `meta`

If pagination metadata is missing, the client falls back to a single-page response.

### Error envelope

The client expects one of these error shapes:

```json
{
  "error": {
    "code": "backend_code",
    "message": "Human readable message",
    "details": "Optional detail",
    "request_id": "Optional request trace",
    "status_code": 500
  }
}
```

or

```json
{
  "error": "Human readable message"
}
```

### Model assumptions

The app currently assumes:

- JSON uses `snake_case`
- dates are ISO8601 strings
- book sources may include `kindle_export`, `manual_import`, or unknown variants
- import status values may vary slightly, so the client tolerates synonyms like `queued`, `pending`, `success`, and `error`
- search may be performed either with a text query or with filters alone if the backend supports it

### Example response shapes

#### `GET /api/books`

```json
{
  "data": {
    "items": [
      {
        "id": "bk_123",
        "title": "The Book",
        "author": "Author Name",
        "source": "kindle_export",
        "highlight_count": 42,
        "note_count": 7,
        "cover_url": null,
        "synopsis": null,
        "last_imported_at": "2026-04-08T12:00:00Z",
        "created_at": "2026-04-01T12:00:00Z",
        "updated_at": "2026-04-08T12:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 100,
      "total": 1,
      "has_more": false,
      "next_page": null
    }
  }
}
```

#### `GET /api/books/{id}`

```json
{
  "data": {
    "book": {
      "id": "bk_123",
      "title": "The Book",
      "author": "Author Name",
      "source": "kindle_export",
      "highlight_count": 42,
      "note_count": 7,
      "cover_url": null,
      "synopsis": null,
      "last_imported_at": "2026-04-08T12:00:00Z",
      "created_at": "2026-04-01T12:00:00Z",
      "updated_at": "2026-04-08T12:00:00Z"
    },
    "stats": {
      "highlight_count": 42,
      "note_count": 7,
      "last_imported_at": "2026-04-08T12:00:00Z",
      "first_highlight_at": "2026-03-20T12:00:00Z",
      "latest_highlight_at": "2026-04-08T12:00:00Z"
    }
  }
}
```

#### `GET /api/books/{id}/highlights`

```json
{
  "data": {
    "highlights": [
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
        "updated_at": "2026-04-08T12:00:00Z",
        "book": null
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 24,
      "total": 1,
      "has_more": false,
      "next_page": null
    }
  }
}
```

#### `GET /api/search`

```json
{
  "data": {
    "results": [
      {
        "highlight": {
          "id": "hl_123",
          "book_id": "bk_123",
          "text": "Highlighted passage",
          "note": "Optional note"
        },
        "book": {
          "id": "bk_123",
          "title": "The Book",
          "author": "Author Name"
        },
        "matched_terms": ["passage"],
        "snippet": "…Highlighted passage…",
        "matched_in_note": false,
        "matched_field": "text"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 1,
      "has_more": false,
      "next_page": null
    }
  }
}
```

#### `POST /api/imports/kindle/preview`

Request body:

```json
{
  "source": "kindle_txt",
  "raw_text": "Full Kindle export text",
  "filename": "My Clippings.txt",
  "dry_run": true
}
```

Example response:

```json
{
  "data": {
    "summary": {
      "books_detected": 2,
      "highlights_detected": 18,
      "notes_detected": 4,
      "duplicates_detected": 1,
      "warnings_count": 1,
      "warnings": ["One malformed section was skipped."]
    },
    "detected_books": [
      {
        "id": "tmp_1",
        "title": "The Book",
        "author": "Author Name",
        "highlights_detected": 12,
        "notes_detected": 3
      }
    ],
    "message": "Preview generated."
  }
}
```

#### `POST /api/imports/kindle`

Example response:

```json
{
  "data": {
    "import_id": "imp_123",
    "status": "completed",
    "summary": {
      "books_detected": 2,
      "highlights_detected": 18,
      "notes_detected": 4,
      "duplicates_detected": 1,
      "warnings_count": 1,
      "warnings": ["One malformed section was skipped."]
    },
    "books_created": 1,
    "books_updated": 1,
    "created_at": "2026-04-08T12:00:00Z",
    "completed_at": "2026-04-08T12:00:04Z",
    "filename": "My Clippings.txt",
    "message": "Import completed."
  }
}
```

## Sprint 2 feature coverage

### Library

- improved editorial hierarchy
- sort and filter controls
- pull to refresh
- summary metrics
- recent-import emphasis
- loading skeletons
- cached fallback behavior
- recovery states when backend requests fail

### Book detail

- stronger metadata header
- paginated highlight loading
- deep-linkable highlight focus path
- refined highlight cards with copy/share stubs
- calmer scroll and loading treatment

### Search

- debounced query execution
- filter support for book, author, notes, and sort
- pagination
- recent search memory
- tap-through to exact book and highlight context

### Import

- paste-text flow
- document-picker `.txt` flow
- preview before commit
- import confirmation step
- import summary surfaces
- backend history fetch and inspection
- cached last-success summary restore

### Settings

- backend URL display
- debug-only base URL override
- version and build display
- export actions
- diagnostics summary
- cache clear action

## Local persistence

Current persistence choices are deliberately small and readable:

- file cache for books, book detail, paged highlights, import history, and last import summary
- `UserDefaults` for recent searches
- `UserDefaults` for diagnostics snapshot
- `UserDefaults` for development base URL override

This keeps the app resilient without introducing database migrations or offline merge logic in Sprint 2.

## Config values

Required values live in the xcconfig files:

- `FRAGMENTA_API_BASE_URL`
- `PRODUCT_BUNDLE_IDENTIFIER`
- `DEVELOPMENT_TEAM`

Current defaults:

- `Config/Debug.xcconfig` points to `http://127.0.0.1:3000`
- `Config/Release.xcconfig` points to `https://fragmenta-core.example.com`

App versioning now defaults to:

- `MARKETING_VERSION = 0.2.0`
- `CURRENT_PROJECT_VERSION = 2`

## How networking works

- `AppConfig` reads `FragmentaAPIBaseURL` from `Info.plist`
- `Info.plist` resolves that value from `FRAGMENTA_API_BASE_URL`
- `APIClient` builds typed requests from `APIEndpoint`
- `PublicRequestHeadersProvider` is the current header seam
- auth is intentionally absent in Sprint 2, but the header provider keeps the path open for Sprint 3+

In `DEBUG`, Settings includes a base URL override field. That override is stored locally and used to rebuild the live dependency container without editing source files.

## Xcode setup

### Already done in the repo

- native SwiftUI source files are in place
- `Fragmenta.xcodeproj` exists
- `project.yml` exists and can regenerate the project
- `Info.plist` and xcconfig files are wired

### What you still need to do in Xcode

1. Open the repo folder.
2. Run `xcodegen generate` if you want to refresh the project from `project.yml`.
3. Open `Fragmenta.xcodeproj`.
4. Select the `Fragmenta` target.
5. Set your signing team.
6. Confirm or change `PRODUCT_BUNDLE_IDENTIFIER`.
7. Set `FRAGMENTA_API_BASE_URL` to the correct backend URL for the environment you want.
8. Build and run.

### Notes for local backend development

- If you run `fragmenta-core` locally on the same Mac, the current Debug value is `http://127.0.0.1:3000`.
- If you run on a physical device later, `127.0.0.1` will not point to your Mac. Use your LAN IP, a tunnel, or another reachable development URL instead.

## Validation completed here

Completed in this environment:

- source scaffolding and Sprint 2 wiring
- Xcode project regeneration with `xcodegen generate`
- `plutil -lint Config/Info.plist`

Not completed here:

- opening the project in Xcode
- building against the iOS SDK
- simulator or device execution
- validating share sheet behavior
- validating document picker behavior on-device
- validating clipboard and haptic behavior on-device
- validating pull-to-refresh spinners and navigation polish live

This machine does not have Xcode installed, so final compile/runtime validation still needs to happen on a Mac with Xcode.

## What likely needs light cleanup after opening in Xcode

- any backend field names that differ from the current assumptions
- any endpoint-specific pagination keys that differ from the tolerant defaults
- signing and bundle settings
- simulator or device-specific polish issues
- export/share edge cases depending on actual backend file headers

## Sprint 3 recommendations

- file importer from share sheet and Files app entry points
- richer export and share destinations
- stronger highlight actions and native copy/share affordances
- more precise search-result snippet highlighting
- optimistic refresh and better background refresh patterns
- optional auth once `fragmenta-core` requires it
- cover art handling and image caching if the backend exposes it
- test targets and first-pass UI/state regression coverage once Xcode validation is available
