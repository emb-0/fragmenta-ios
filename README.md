# Fragmenta iOS

Fragmenta iOS is the standalone native SwiftUI client for `fragmenta-core`, the separate Next.js backend that parses Kindle `.txt` exports into books, highlights, notes, imports, and exports.

This repository is intentionally:

- a real native iOS codebase in Swift and SwiftUI
- not a web wrapper
- not React Native
- not Expo
- not a cross-platform scaffold

Sprint 5 is a tight runtime-quality sprint. It keeps Sprint 4’s ingest and share foundations, then pushes the library toward a real native product surface with cover-rich browsing, image caching, faster perceived navigation, and better runtime readiness for tonight’s Xcode pass.

## Sprint 5 snapshot

Sprint 5 adds:

- a real cover-based bookshelf mode alongside the existing journal/list shelf
- remembered library view mode preference
- backend-cover enrichment decoding without introducing any direct Google Books client on iOS
- a dedicated native cover image pipeline with downsampling, memory caching, URL caching, and prefetching
- cover-aware list cards and a stronger cover-rich book detail header
- a tighter reading screen with a notes-only highlight filter
- small runtime-speed improvements for search and cover prefetching
- clearer local cache messaging for cover art and shelf data

## Git state audit

Sprint 5 started by verifying repository state before feature work.

Verified at the start:

- `git status --short --branch` showed `main...origin/main`
- `git branch -vv` showed `main` tracking `origin/main`
- `git remote -v` showed `origin` as `git@github.com:emb-0/fragmenta-ios.git`
- `git log --oneline --decorate -6` showed the Sprint 4 commits on `main`
- there were no pending local changes before Sprint 5 work began

Sprint 5 ends the same way:

- branch: `main`
- upstream: `origin/main`
- remote: `git@github.com:emb-0/fragmenta-ios.git`
- push target: `origin main`

## Important tree changes

```text
fragmenta-ios/
├── Fragmenta/
│   ├── Core/
│   │   └── Images/
│   ├── Features/
│   │   ├── Highlights/
│   │   └── Library/
│   ├── Models/
│   └── Utilities/
├── Config/
├── Fragmenta.xcodeproj
└── README.md
```

Key Sprint 5 additions:

- `Fragmenta/Core/Images/CoverImagePipeline.swift`
- `Fragmenta/Features/Library/BookCoverArtView.swift`
- `Fragmenta/Features/Library/LibraryViewMode.swift`

Key Sprint 5 updates:

- `Fragmenta/Models/Book.swift`
- `Fragmenta/Features/Library/LibraryView.swift`
- `Fragmenta/Features/Library/LibraryViewModel.swift`
- `Fragmenta/Features/Library/BookShelfCardView.swift`
- `Fragmenta/Features/Highlights/BookDetailView.swift`
- `Fragmenta/Features/Highlights/BookDetailViewModel.swift`
- `Fragmenta/Core/AppPreferencesStore.swift`
- `Fragmenta/Core/AppState.swift`

## Sprint 5 implementation notes

### Bookshelf view

The library now supports two modes:

- `Journal`
- `Bookshelf`

`Journal` preserves the existing text-forward editorial shelf.

`Bookshelf` adds:

- cover-led browsing in a lazy grid
- a smaller “Front shelf” strip for recent or prominent books
- premium fallback covers when no remote cover exists
- smooth tap-through into the existing book detail flow

The preferred view mode is persisted locally through `AppPreferencesStore`.

### Backend cover enrichment assumptions

Fragmenta iOS does not call Google Books or any other third-party enrichment provider directly.

All enrichment is assumed to be backend-owned by `fragmenta-core`.

The client now tolerates multiple backend cover shapes, including:

- nested `cover` objects
- nested `enrichment.cover` objects
- top-level fields such as:
  - `cover_url`
  - `cover_thumbnail_url`
  - `cover_large_url`
  - `cover_background_hex`
  - `cover_foreground_hex`
  - `cover_width`
  - `cover_height`

This keeps the iOS client flexible if `fragmenta-core` adjusts its enrichment payload slightly.

### Cover image loading and caching

Sprint 5 adds a dedicated image pipeline instead of leaning on default `AsyncImage` behavior.

The cover stack now uses:

- `NSCache` for in-memory cover reuse
- `URLCache` through a dedicated `URLSession` for HTTP response caching
- image downsampling before view rendering
- request de-duplication for in-flight image fetches
- eager prefetching of the most visible library covers

The goal is pragmatic runtime smoothness:

- less janky scrolling
- less re-decoding while browsing
- more stable covers in repeated navigation

### Library runtime polish

Sprint 5 keeps the library tight:

- fast view-mode switching
- cover prefetching for the first visible shelf items
- no extra metadata client or duplicate enrichment pipeline
- preserved journal mode for users who want a text-first shelf

### Reading and detail polish

The book detail screen now supports:

- a cover-led hero when art is available
- the same fallback cover language when it is not
- a local `All Highlights` / `With Notes` filter
- preserved copy/share/export actions from Sprint 4
- a smoother first impression when book detail cover art is available

### Search and settings refinements

Sprint 5 includes a few small runtime wins:

- slightly faster search debounce
- clearer Settings messaging that cover art is part of the local cache
- cache clearing now reflects the broader runtime state more honestly

## Local persistence

Fragmenta now uses these lightweight persistence layers:

- `Caches/FragmentaCache` for library, book detail, import, and export payload caching
- `UserDefaults` for recent searches, diagnostics, debug base URL override, and preferred library view mode
- app-group-backed pending import draft storage for share-extension handoff
- in-memory cover cache plus URL-backed cover response cache for artwork

This remains intentionally lightweight. Sprint 5 is not an offline sync engine.

## Backend assumptions

Fragmenta still assumes a public backend with no auth in Sprint 5.

Expected endpoints still include:

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

Additional Sprint 5 assumptions:

- book payloads may now include backend-owned enrichment or cover metadata
- thumbnail and larger cover URLs may both be present
- the best bookshelf image may differ from the best detail image

Transport assumptions remain:

- success responses use a `data` envelope
- errors use an `error` object or string
- payloads are `snake_case`
- dates are ISO8601 strings

## Config values

No new required config values were added in Sprint 5.

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
- `MARKETING_VERSION = 0.5.0`
- `CURRENT_PROJECT_VERSION = 5`

Environment notes:

- `Config/Debug.xcconfig` points at `http://127.0.0.1:3000`
- `Config/Release.xcconfig` points at `https://fragmenta-core.example.com`

`127.0.0.1` is correct for an iOS simulator on the same Mac. It is not correct for a physical device.

## Exact Xcode validation steps for tonight

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
   - launch and initial library load
   - switch between `Journal` and `Bookshelf` modes
   - bookshelf scrolling with many books
   - cover loading, reuse, and fallback behavior
   - navigation from both library modes into book detail
   - book detail with and without cover art
   - notes-only highlight filter in book detail
   - search tap-through into focused highlight context
   - import via pasted text
   - import via document picker
   - opening a `.txt` file into Fragmenta from Files
   - book markdown export/share
   - share-extension handoff from shared text or a shared `.txt` file

## Validation completed here

Completed in this environment:

- git audit of local branch, upstream, remote, and recent commits
- Sprint 5 source changes
- `xcodegen generate`
- `plutil -lint Config/Info.plist`
- `plutil -lint Config/ShareExtension-Info.plist`
- `plutil -lint` for both entitlements files
- `git diff --check`

Not completed here:

- compiling against the iOS SDK in Xcode
- simulator execution
- device execution
- runtime verification of the new cover pipeline
- performance validation with a large real book set
- direct Files/share-extension ingest validation on-device

This machine still does not have Xcode installed, so those checks remain real follow-up work.

## What still needs real runtime or device verification

- first compile across the app target and share-extension target
- real-world cover loading behavior with backend-provided enrichment payloads
- scroll smoothness in bookshelf mode with a larger library
- cover cache reuse after navigating in and out of detail repeatedly
- direct `.txt` open from Files into Fragmenta
- share-extension handoff from other apps
- share sheet presentation for exports
- final spacing and behavior on real iPhone hardware

## Sprint 6 recommendations

- validate and harden the cover payload contract against the real backend
- refine bookshelf mode once real device performance is measured
- add targeted tests around cover decoding and library view-mode persistence
- tune any remaining SwiftUI/runtime issues discovered during the first full Xcode pass
- only expand product scope again after the real runtime validation loop is stable
