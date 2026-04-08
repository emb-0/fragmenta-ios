# Fragmenta iOS

Fragmenta iOS is the standalone native SwiftUI client for `fragmenta-core`, the separate Next.js backend that parses Kindle `.txt` exports into books, highlights, notes, collections, insights, discovery surfaces, imports, and exports.

This repository is intentionally:

- a real native iOS codebase in Swift and SwiftUI
- not a web wrapper
- not React Native
- not Expo
- not a cross-platform scaffold

Sprint 6 extends the already-connected app into a more complete product surface: reading insights, collections, backend share cards, AI-backed discovery, stronger cache behavior, and a tighter runtime-readiness pass for real Xcode validation.

## Sprint 6 snapshot

Sprint 6 adds:

- a new `Insights` tab with native reading stats surfaces
- backend-driven collections and collection detail flows
- book-to-collection membership management from book detail
- backend share-card download and share flow for highlights
- semantic search mode as a backend toggle
- book-level discovery surfaces for AI summary and related highlights
- broader file-backed caching plus an in-memory cache layer for faster repeat reads
- deeper diagnostics coverage for insights, collections, discovery, and share cards

## Git state audit

Sprint 6 started by verifying repository state before feature work.

Verified at the start:

- `git status --short --branch` showed `main...origin/main`
- `git branch -vv` showed `main` tracking `origin/main`
- `git remote -v` showed `origin` as `git@github.com:emb-0/fragmenta-ios.git`
- the recent commit history showed Sprint 5 already on `main`
- there were no pending local changes before Sprint 6 work began

Sprint 6 also ends on:

- branch: `main`
- upstream: `origin/main`
- remote: `git@github.com:emb-0/fragmenta-ios.git`
- push target: `origin main`
- pushed Sprint 6 head: `5f55455`
- Sprint 6 feature commit: `3c4c1f5`
- Sprint 6 handoff commit: `99c0957`
- Sprint 6 push-state commit: `5f55455`

## Important tree changes

```text
fragmenta-ios/
├── Fragmenta/
│   ├── Features/
│   │   ├── Collections/
│   │   ├── Highlights/
│   │   ├── Import/
│   │   ├── Insights/
│   │   ├── Library/
│   │   ├── Search/
│   │   └── Settings/
│   ├── Models/
│   ├── Services/
│   └── Core/
├── Config/
├── Fragmenta.xcodeproj
└── README.md
```

Key Sprint 6 additions:

- `Fragmenta/Features/Insights/InsightsView.swift`
- `Fragmenta/Features/Insights/InsightsViewModel.swift`
- `Fragmenta/Features/Collections/CollectionsView.swift`
- `Fragmenta/Features/Collections/CollectionsViewModel.swift`
- `Fragmenta/Models/ReadingInsights.swift`
- `Fragmenta/Models/Collection.swift`
- `Fragmenta/Models/BookDiscovery.swift`
- `Fragmenta/Models/ShareCardArtifact.swift`
- `Fragmenta/Services/InsightsService.swift`
- `Fragmenta/Services/CollectionsService.swift`
- `Fragmenta/Services/DiscoveryService.swift`
- `Fragmenta/Services/ShareCardService.swift`

Key Sprint 6 updates:

- `Fragmenta/App/RootView.swift`
- `Fragmenta/Core/AppContainer.swift`
- `Fragmenta/Core/AppState.swift`
- `Fragmenta/Core/DiagnosticsStore.swift`
- `Fragmenta/Core/FragmentaCacheStore.swift`
- `Fragmenta/Features/Highlights/BookDetailView.swift`
- `Fragmenta/Features/Highlights/BookDetailViewModel.swift`
- `Fragmenta/Features/Highlights/HighlightCardView.swift`
- `Fragmenta/Features/Import/ImportView.swift`
- `Fragmenta/Features/Library/LibraryView.swift`
- `Fragmenta/Features/Search/SearchView.swift`
- `Fragmenta/Features/Search/SearchViewModel.swift`
- `Fragmenta/Features/Search/SearchResultRowView.swift`
- `Fragmenta/Features/Settings/SettingsView.swift`
- `Fragmenta/Services/API/APIClient.swift`
- `Fragmenta/Services/API/APIEndpoint.swift`
- `Fragmenta/Services/SearchService.swift`

## Sprint 6 implementation notes

### Insights

Sprint 6 adds a dedicated native `Insights` tab that consumes backend-owned stats rather than inventing a client analytics layer.

The screen now supports:

- total books, highlights, and notes
- pace summary cards
- reading activity plotted over time
- top annotated books
- most annotated passages
- cached-first loading with graceful saved-state fallback

The charts are intentionally restrained. The goal is a private reading ledger, not a loud dashboard.

### Collections and tags

Fragmenta now consumes backend collections as first-class organizational surfaces.

The app includes:

- collection list screen
- collection detail screen
- tag display when the backend exposes tags
- add/remove book membership flow from book detail
- local caching for collection lists and collection detail payloads

The membership sheet assumes the backend can return a book-scoped collections response that includes membership state for the current book, rather than only returning collections the book already belongs to.

### Share cards

Sprint 6 adds highlight share-card handling through the backend.

The iOS client:

- requests a backend-generated share card for a highlight
- stores the returned image in the caches directory
- reuses the cached file on repeated requests
- presents the image through a native preview sheet
- hands the image off through the native share sheet

This is intentionally backend-owned. Fragmenta iOS does not render its own quote card image pipeline.

### AI discovery

Sprint 6 adds subtle AI-backed discovery surfaces without turning the app into an AI-first product.

The app now supports:

- semantic search mode as a backend query mode
- book-level summary surface
- theme chips when the backend returns them
- related highlights in book detail
- graceful degradation when AI endpoints are empty or unavailable

The iOS client does not create a second AI pipeline. It only consumes backend responses from `fragmenta-core`.

### Offline and cache behavior

Sprint 6 strengthens offline-friendly behavior without introducing full sync complexity.

The current cache strategy includes:

- file-backed JSON caching in `Caches/FragmentaCache`
- a new in-memory data cache layered into `FragmentaCacheStore`
- cached library payloads
- cached book detail and highlight pages
- cached search result pages
- cached reading insights
- cached collection lists and collection detail payloads
- cached discovery payloads
- cached import history and last import response
- persistent recent searches and diagnostics through `UserDefaults`

This is still intentionally lightweight. Fragmenta is not doing offline conflict resolution or sync orchestration in Sprint 6.

## Backend assumptions

Fragmenta still assumes a public backend with no auth in Sprint 6.

Expected existing endpoints still include:

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

Sprint 6 adds these backend assumptions:

- `GET /api/insights/reading`
- `GET /api/collections`
- `GET /api/collections/{id}`
- `GET /api/books/{id}/collections`
- `POST /api/collections/{id}/books`
- `DELETE /api/collections/{id}/books/{book_id}`
- `GET /api/highlights/{id}/share-card`
- `GET /api/books/{id}/summary`
- `GET /api/books/{id}/related-highlights`
- semantic search is represented as `GET /api/search?...&mode=semantic`

Payload assumptions remain:

- success responses use a `data` envelope
- errors use an `error` object or string
- payloads are `snake_case`
- dates are ISO8601 strings

Flexibility assumptions now built into the client:

- stats payloads may use either nested totals/activity objects or flatter count/timeline fields
- collections may expose tags as strings or tag objects
- AI theme payloads may arrive as strings or richer objects
- related highlights may arrive nested under `highlight` or as flatter highlight-shaped objects

## Config values

Sprint 6 does not add any new required config keys.

You still need to set:

- `FRAGMENTA_API_BASE_URL`
- `FRAGMENTA_APP_GROUP_IDENTIFIER`
- `PRODUCT_BUNDLE_IDENTIFIER`
- `FRAGMENTA_SHARE_EXTENSION_BUNDLE_IDENTIFIER`
- `DEVELOPMENT_TEAM`

Current defaults in `Config/Base.xcconfig`:

- `PRODUCT_BUNDLE_IDENTIFIER = com.fragmenta.ios`
- `FRAGMENTA_SHARE_EXTENSION_BUNDLE_IDENTIFIER = com.fragmenta.ios.share`
- `FRAGMENTA_APP_GROUP_IDENTIFIER = group.com.fragmenta.shared`
- `MARKETING_VERSION = 0.6.0`
- `CURRENT_PROJECT_VERSION = 6`

Environment notes:

- `Config/Debug.xcconfig` points at `http://127.0.0.1:3000`
- `Config/Release.xcconfig` points at `https://fragmenta-core.example.com`

`127.0.0.1` is correct for an iOS simulator on the same Mac. It is not correct for a physical device.

## Exact Xcode validation steps

When you get back to Xcode:

1. Open `/Users/emmettbell/claude/Code/fragmenta-ios`.
2. Run `xcodegen generate` if you want to regenerate from `project.yml`.
3. Open `Fragmenta.xcodeproj`.
4. Set signing for:
   - `Fragmenta`
   - `FragmentaShareExtension`
5. Confirm:
   - `PRODUCT_BUNDLE_IDENTIFIER`
   - `FRAGMENTA_SHARE_EXTENSION_BUNDLE_IDENTIFIER`
   - `FRAGMENTA_API_BASE_URL`
   - `FRAGMENTA_APP_GROUP_IDENTIFIER`
6. Ensure the App Groups capability is applied to both targets with the same group identifier.
7. Build the app target first.
8. Validate these flows in order:
   - app launch and initial tab shell
   - library load in `Journal` and `Bookshelf`
   - bookshelf scrolling with many covers
   - transition from library into book detail
   - insights load, chart rendering, and cached fallback behavior
   - collections list and collection detail
   - adding and removing a book from collections via the book detail sheet
   - semantic search mode
   - search tap-through into focused highlight context
   - book discovery summary and related highlights
   - highlight copy/share/share-card flow
   - import via pasted text
   - import via document picker
   - open-from-Files ingestion
   - share-extension handoff
   - settings diagnostics and cache clear

## Validation completed here

Completed in this environment:

- git audit of local branch, upstream, remote, and recent state
- Sprint 6 source changes
- `xcodegen generate`
- `plutil -lint Config/Info.plist`
- `plutil -lint Config/ShareExtension-Info.plist`
- `plutil -lint` for both entitlements files
- `git diff --check`

Not completed here:

- compiling against the iOS SDK in Xcode
- simulator execution
- device execution
- runtime validation of Charts rendering
- runtime validation of collection membership mutations
- runtime validation of share-card image generation and preview handoff
- runtime validation of semantic search and book-discovery responses against the live backend

## What still needs real runtime or device verification

- first compile across the app target and share-extension target
- real backend compatibility for the new insights payload shape
- real backend compatibility for collection membership responses
- real backend compatibility for semantic search, book summaries, and related highlights
- runtime behavior of highlight share-card downloads and preview/share handoff
- chart performance and rendering polish on actual devices
- collection membership sheet behavior against real data
- direct Files/share-extension ingest on device
- final scroll smoothness and tab/navigation feel on real hardware

## Sprint 7 recommendations

- validate the new backend contracts against real responses and tighten any decode mismatches
- fix any first-build or first-runtime issues discovered in Xcode tonight
- add targeted tests around stats decoding, collection membership caching, and share-card caching
- refine discovery/search behavior once the real semantic backend behavior is known
- only expand scope again after the runtime validation loop is stable
